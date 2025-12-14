#!/bin/bash
exec > /var/log/user-data.log 2>&1

echo "User data started at $(date)"


# 기본 패키지 설치 (AL2023)
dnf update -y
dnf install -y python3 python3-pip git awscli amazon-cloudwatch-agent

# ECS Agent 비활성화 (ECS 미사용)
systemctl stop ecs || true
systemctl disable ecs || true

# 앱 디렉토리
mkdir -p /opt/kepco-chatbot
chown ec2-user:ec2-user /opt/kepco-chatbot


# Python venv
sudo -u ec2-user python3 -m venv /opt/kepco-chatbot/venv
sudo -u ec2-user /opt/kepco-chatbot/venv/bin/pip install --upgrade pip
sudo -u ec2-user /opt/kepco-chatbot/venv/bin/pip install streamlit boto3

# SSM Agent (AL2023 기본 포함)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Streamlit 앱 생성
cat <<'EOF' >/opt/kepco-chatbot/app.py
import streamlit as st
import boto3
import uuid
import os

# 페이지 설정
st.set_page_config(
    page_title="한국전력공사 AI 챗봇",
    page_icon="⚡",
    layout="wide"
)

# CSS 스타일링
st.markdown("""
<style>
.main-header {
    background: linear-gradient(90deg, #43CBFF 0%, #9708CC 100%);
    padding: 1rem;
    border-radius: 10px;
    margin-bottom: 2rem;
}
.main-header h1 {
    color: white;
    text-align: center;
    margin: 0;
}
.chat-container {
    max-height: 500px;
    overflow-y: auto;
    padding: 1rem;
    border: 1px solid #ddd;
    border-radius: 10px;
    background-color: #f9f9f9;
}
.user-message {
    background-color: #007bff;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 15px;
    margin: 0.5rem 0;
    text-align: right;
}
.bot-message {
    background-color: #e9ecef;
    color: #333;
    padding: 0.5rem 1rem;
    border-radius: 15px;
    margin: 0.5rem 0;
}
.session-info {
    background-color: #f8f9fa;
    padding: 0.5rem;
    border-radius: 5px;
    font-size: 0.8rem;
    color: #666;
}
</style>
""", unsafe_allow_html=True)

# AWS 클라이언트 초기화
@st.cache_resource
def init_bedrock_client():
    try:
        bedrock_agent = boto3.client(
            'bedrock-agent-runtime',
            region_name=os.getenv('AWS_REGION', 'us-east-1')
        )
        return bedrock_agent
    except Exception as e:
        st.error(f"Bedrock 클라이언트 초기화 실패: {str(e)}")
        return None

# 세션 ID 생성 함수
def generate_session_id():
    return str(uuid.uuid4())

# 베드락 에이전트 호출 함수
def invoke_bedrock_agent(bedrock_client, session_id, user_input):
    if not bedrock_client:
        return "서비스 연결에 문제가 있습니다. 관리자에게 문의하세요."
    
    try:
        agent_id = os.getenv('BEDROCK_AGENT_ID')
        agent_alias_id = os.getenv('BEDROCK_AGENT_ALIAS_ID')
        
        if not agent_id or not agent_alias_id:
            return "에이전트 설정이 완료되지 않았습니다. 관리자에게 문의하세요."
        
        response = bedrock_client.invoke_agent(
            agentId=agent_id,
            agentAliasId=agent_alias_id,
            sessionId=session_id,
            inputText=user_input
        )
        
        # 스트리밍 응답 처리
        completion = ""
        for event in response['completion']:
            if 'chunk' in event:
                chunk = event['chunk']
                if 'bytes' in chunk:
                    completion += chunk['bytes'].decode('utf-8')
        
        return completion if completion else "응답을 받지 못했습니다. 다시 시도해주세요."
        
    except Exception as e:
        st.error(f"에이전트 호출 실패: {str(e)}")
        return "죄송합니다. 현재 서비스에 문제가 발생했습니다. 잠시 후 다시 시도해주세요."

# 메인 애플리케이션
def main():
    # 헤더
    st.markdown("""
    <div class="main-header">
        <h1>⚡ 한국전력공사 AI 챗봇</h1>
    </div>
    """, unsafe_allow_html=True)
    
    # 안내 메시지
    st.info("""
    🔍 **한국전력공사 AI 챗봇에 오신 것을 환영합니다!**
    
    이 챗봇은 다음과 같은 질문에 답변할 수 있습니다:

    - 한국전력공사 사규 및 규정 관련 문의
    - 업무 매뉴얼 및 절차 안내
    - 전력 관련 기술 정보
    - 기타 한국전력공사 관련 정보
    
    💡 궁금한 내용을 자유롭게 질문해보세요!
    """)
    
    # Bedrock 클라이언트 초기화
    bedrock_client = init_bedrock_client()
    
    if not bedrock_client:
        st.error("Bedrock 서비스 초기화에 실패했습니다. 페이지를 새로고침하거나 관리자에게 문의하세요.")
        return
    
    # 세션 상태 초기화 (Streamlit 내장 세션 사용)
    if 'session_id' not in st.session_state:
        st.session_state.session_id = generate_session_id()
    if 'messages' not in st.session_state:
        st.session_state.messages = []
    
    # 사이드바 - 세션 정보 및 컨트롤
    with st.sidebar:
        st.markdown("### 📋 세션 정보")
        st.markdown(f"""
        <div class="session-info">
            <strong>세션 ID:</strong><br>
            {st.session_state.session_id[:8]}...
        </div>
        """, unsafe_allow_html=True)
        
        st.markdown(f"**메시지 수:** {len(st.session_state.messages)}")
        
        # 세션 종료 버튼
        if st.button("🔄 새 세션 시작", type="primary", use_container_width=True):
            # 새 세션 생성
            st.session_state.session_id = generate_session_id()
            st.session_state.messages = []
            st.rerun()
        
        st.markdown("---")
        st.markdown("""
        ### 💡 사용 팁
        - 구체적인 질문일수록 정확한 답변을 받을 수 있습니다
        - 사규나 매뉴얼의 특정 조항을 언급해보세요
        - 이전 대화 내용을 참고하여 연속적인 질문이 가능합니다
        """)
    
    # 채팅 히스토리 표시
    if st.session_state.messages:
        st.markdown("### 💬 대화 내역")
        
        for message in st.session_state.messages:
            if message["role"] == "user":
                st.markdown(f"""
                <div class="user-message">
                    👤 {message["content"]}
                </div>
                """, unsafe_allow_html=True)
            else:
                st.markdown(f"""
                <div class="bot-message">
                    🤖 {message["content"]}
                </div>
                """, unsafe_allow_html=True)
    
    # 채팅 입력
    st.markdown("### ✍️ 메시지 입력")
    
    with st.form(key="chat_form", clear_on_submit=True):
        user_input = st.text_area(
            "질문을 입력하세요:",
            placeholder="예: 한국전력공사의 안전관리 규정에 대해 알려주세요.",
            height=100
        )
        
        col1, col2 = st.columns([1, 4])
        with col1:
            submit_button = st.form_submit_button("📤 전송", type="primary")
        
        if submit_button and user_input.strip():
            # 사용자 메시지 추가
            st.session_state.messages.append({"role": "user", "content": user_input})
            
            # 로딩 표시
            with st.spinner("🤖 AI가 답변을 생성하고 있습니다..."):
                # 베드락 에이전트 호출
                bot_response = invoke_bedrock_agent(
                    bedrock_client,
                    st.session_state.session_id,
                    user_input
                )
            
            # 봇 응답 추가
            st.session_state.messages.append({"role": "assistant", "content": bot_response})
            
            # 페이지 새로고침
            st.rerun()
    
    # 페이지 하단 정보
    st.markdown("---")
    st.markdown("""
    <div style="text-align: center; color: #666; font-size: 0.8rem;">
        ⚡ 한국전력공사 AI 챗봇 | Powered by Amazon Bedrock
    </div>
    """, unsafe_allow_html=True)

if __name__ == "__main__":
    main()
EOF

chown ec2-user:ec2-user /opt/kepco-chatbot/app.py

# systemd 서비스
cat <<EOF >/etc/systemd/system/kepco-chatbot.service
[Unit]
Description=KEPCO Chatbot
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/kepco-chatbot
Environment="PATH=/opt/kepco-chatbot/venv/bin:/usr/bin"
Environment="BEDROCK_AGENT_ID=${bedrock_agent_id}"
Environment="BEDROCK_AGENT_ALIAS_ID=${bedrock_agent_alias_id}"
Environment="AWS_REGION=us-east-1"
ExecStart=/opt/kepco-chatbot/venv/bin/streamlit run app.py \
  --server.address 0.0.0.0 \
  --server.port 8501
Restart=always
StandardOutput=append:/var/log/kepco-chatbot.log
StandardError=append:/var/log/kepco-chatbot.log
[Install]
WantedBy=multi-user.target
EOF

# 서비스 시작
systemctl daemon-reload
systemctl enable kepco-chatbot
systemctl start kepco-chatbot

# CloudWatch Agent 설정
cat <<'EOF' >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/kepco-chatbot.log",
            "log_group_name": "/aws/ec2/kepco-chatbot",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/kepco-userdata",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# CloudWatch Agent 시작
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a stop || true

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# 최종 확인
systemctl status kepco-chatbot --no-pager || true
systemctl status amazon-cloudwatch-agent --no-pager || true
ss -tlnp | grep 8501 || true

echo "User data completed at $(date)"
