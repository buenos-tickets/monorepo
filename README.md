# Buenos Tickets Monorepo

티켓 판매 시스템 (Tango Event)

---

## 📁 프로젝트 구조

```
monorepo/
├── frontend/              # 프론트엔드 (HTML/CSS/JS)
│   ├── x402.html         # x402 가스리스 결제 페이지
│   ├── customer.html     # 고객용 페이지
│   └── assets/           # 이미지 등 정적 파일
│
├── backend/              # 백엔드 (Node.js)
│   ├── server.js         # CDP Facilitator 서버
│   ├── package.json      # npm 의존성
│   ├── .env.example      # 환경 변수 예시
│   └── README.md         # 백엔드 가이드
│
└── contracts/            # 스마트 컨트랙트 (Solidity)
    └── BuenosTickets/    # 티켓 컨트랙트
```

---

## 🚀 빠른 시작

### 1. 프론트엔드 (이미 실행 중)

**Cursor Live Server 사용:**
```
http://127.0.0.1:5500/frontend/x402.html
```

### 2. 백엔드 (CDP Facilitator)

```bash
# 백엔드 폴더로 이동
cd backend

# 의존성 설치
npm install

# 환경 변수 설정
cp .env.example .env
nano .env  # CDP API Keys 입력

# 서버 시작
npm start
```

자세한 내용은 [`backend/README.md`](./backend/README.md) 참조

---

## 🎯 x402 가스리스 결제

### 동작 원리

```
사용자 (x402.html)
    ↓ 서명 (가스비 없음)
CDP Facilitator (backend/server.js)
    ↓ 가스비 지불 & 전송
Base Sepolia 블록체인
```

### 필요한 것

1. **CDP API Keys** (무료)
   - https://portal.cdp.coinbase.com/
   
2. **Base Sepolia USDC** (무료)
   - https://faucet.circle.com/

3. **Base Sepolia ETH** (무료, Facilitator용)
   - https://www.alchemy.com/faucets/base-sepolia

---

## 📋 사용 방법

### STEP 1: 백엔드 서버 시작

```bash
cd backend
npm install
cp .env.example .env
# .env 파일에 CDP API Keys 입력
npm start
```

### STEP 2: 프론트엔드 접속

```
http://127.0.0.1:5500/frontend/x402.html
```

### STEP 3: 결제 테스트

1. "Pay Now" 버튼 클릭
2. MetaMask 서명
3. CDP Facilitator가 자동 처리
4. ✅ 완료!

---

## 🏗️ 기술 스택

### 프론트엔드
- HTML5, CSS3, JavaScript (Vanilla)
- ethers.js v5.7.2
- MetaMask 통합

### 백엔드
- Node.js + Express
- @coinbase/coinbase-sdk
- ethers.js v5.7.2

### 블록체인
- Base Sepolia Testnet
- USDC Token
- x402 Protocol

---

## 🔐 보안

⚠️ **중요:**
- `.env` 파일을 절대 git에 커밋하지 마세요
- CDP API Keys는 백엔드에만 보관
- 테스트넷만 사용 (Base Sepolia)

---

## 📚 문서

- [Backend README](./backend/README.md) - 백엔드 상세 가이드
- [CDP Documentation](https://docs.cdp.coinbase.com/)
- [x402 Protocol](https://x402.gitbook.io/x402)

---

## 🆘 문제 해결

### 백엔드 서버가 안 켜져요
```bash
cd backend
npm install
node server.js
```

### CDP API Keys가 없어요
https://portal.cdp.coinbase.com/ 에서 발급

### USDC가 없어요
https://faucet.circle.com/ 에서 받기

---

## 📄 라이선스

MIT License
