<img width="947" height="861" alt="Image" src="https://github.com/user-attachments/assets/0988ae53-88e7-4beb-8c76-860d098f4954" />

# KEPCO 챗봇 인프라 배포 가이드

## 🏗️ 아키텍처

```
Internet Gateway
    ↓
ALB (퍼블릭 서브넷)
    ↓
EC2 (프라이빗 서브넷) ← 사용자 접속
    ↓
Amazon Bedrock Agent
```

## 🚀 배포 단계

### 1. 사전 준비
```bash
# AWS CLI 설정
aws configure

# Terraform 설치 확인
terraform version

# Terraform 배포
terraform apply
```

### 2. 접속 확인
```bash
# 출력된 URL로 접속
# 예: http://1.2.3.4:8501
```

## 🔧 베드락 에이전트 설정

배포 후 실제 베드락 에이전트를 사용하려면:

1. **AWS Bedrock에서 Agent 생성**
2. **Knowledge Base 연결**
3. **Agent ID와 Alias ID 확인**
4. **EC2(user data)에서 환경 변수 설정**:

## 🗑️ 리소스 정리

```bash
terraform destroy
```

## 📋 주요 출력 값

- `ec2_public_ip`: EC2 퍼블릭 IP
- `streamlit_url`: 챗봇 접속 URL
- `vpc_id`: VPC ID


## 배포 후 꼭 확인할 것 (순서대로)
sudo cat /var/log/user-data.log

sudo cat /var/log/cloud-init-output.log

systemctl status kepco-chatbot

journalctl -u kepco-chatbot -n 50 --no-pager
