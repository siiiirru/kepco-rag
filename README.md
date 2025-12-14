# KEPCO 챗봇 인프라 배포 가이드

## 🏗️ 아키텍처

```
Internet Gateway
    ↓
EC2 (퍼블릭 서브넷) ← 사용자 접속
    ↓
ElastiCache Valkey (프라이빗 서브넷)
    ↓
Amazon Bedrock Agent
```

## 💰 비용 최적화 설정

- **EC2**: t3.micro (프리티어)
- **ElastiCache**: cache.t3.micro (최소 사양)
- **VPC**: 기본 설정 (무료)
- **보안**: 암호화 비활성화로 비용 절약

## 🚀 배포 단계

### 1. 사전 준비
```bash
# AWS CLI 설정
aws configure

# Terraform 설치 확인
terraform version
```

### 2. 변수 설정
```bash
# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 필요시 값 수정
vim terraform.tfvars
```

### 3. 인프라 배포
```bash
# 초기화
terraform init

# 계획 확인
terraform plan

# 배포 실행
terraform apply
```

### 4. 접속 확인
```bash
# 출력된 URL로 접속
# 예: http://1.2.3.4:8501
```

## 🔧 베드락 에이전트 설정

배포 후 실제 베드락 에이전트를 사용하려면:

1. **AWS Bedrock에서 Agent 생성**
2. **Knowledge Base 연결**
3. **Agent ID와 Alias ID 확인**
4. **EC2에서 환경 변수 설정**:
   ```bash
   sudo systemctl stop kepco-chatbot
   
   # /opt/kepco-chatbot/.env 파일 생성
   echo "BEDROCK_AGENT_ID=your-agent-id" | sudo tee /opt/kepco-chatbot/.env
   echo "BEDROCK_AGENT_ALIAS_ID=your-alias-id" | sudo tee -a /opt/kepco-chatbot/.env
   
   sudo systemctl start kepco-chatbot
   ```

## 🗑️ 리소스 정리

```bash
terraform destroy
```

## 📋 주요 출력 값

- `ec2_public_ip`: EC2 퍼블릭 IP
- `streamlit_url`: 챗봇 접속 URL
- `elasticache_endpoint`: Redis 엔드포인트
- `vpc_id`: VPC ID

## 🔒 보안 고려사항

- EC2는 퍼블릭 서브넷에 위치 (비용 절약)
- 보안 그룹으로 접근 제한
- IAM 최소 권한 원칙 적용
- ElastiCache는 프라이빗 서브넷에 격리

## 배포 후 꼭 확인할 것 (순서대로)
sudo cat /var/log/user-data.log

sudo cat /var/log/cloud-init-output.log

systemctl status kepco-chatbot

journalctl -u kepco-chatbot -n 50 --no-pager