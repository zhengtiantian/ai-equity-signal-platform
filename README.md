# AI-Driven Equity Signal Platform

An end-to-end quantitative research and signal generation platform that processes financial news through LLM pipelines to produce daily equity trading signals across 100 US stocks.

## Platform Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA COLLECTION LAYER                             │
│         GDELT (8TB+) │ Finnhub │ NewsAPI │ Yahoo Finance │ FMP          │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ raw news
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       NLP / LLM LABELING LAYER                           │
│                                                                           │
│   SLM company match ──▶  Pass A: Gemma 3B  ──┐                          │
│                                               ├──▶ Snorkel (77.3% agr.) │
│                          Pass B: Qwen 4B   ──┘                          │
│                                    │                                     │
│                       llm_sentiment_final / event_type                  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ 840K labeled articles
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      FEATURE ENGINEERING LAYER                           │
│                                                                           │
│   News:  article_count, news_burst_20d, quality_score, full_ratio       │
│   LLM:   avg_sentiment_3d/5d, sentiment_shift_5d, high_signal_count     │
│   Earn:  surprise_pct_last, days_to_earnings, earnings_recency_weight   │
│   Price: past_ret_20d/60d, volatility_20d/60d, volume_shock_20d         │
│   Alt:   macro_*, retail_*, analyst_*, inst_holding_*, ah_gap/pm_gap    │
│                                                                           │
│   → 189K+ rows │ 100 symbols │ 7 return horizons (5–60d)               │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          ML MODEL LAYER                                   │
│                                                                           │
│   Ridge ──┐                                                              │
│           ├──▶ Ensemble ──▶ Walk-forward IC=0.059 │ Sharpe=0.85         │
│   LightGBM┘               Long-short return +21.7% annualized           │
│                                                                           │
│   MLflow: experiment tracking │ SHAP: feature importance                │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ daily signals
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       SERVING / PLATFORM LAYER                           │
│                                                                           │
│   Kafka ──▶ signal distribution ──▶ alerts / position tracking          │
│   Spring Boot REST API (Keycloak JWT)                                   │
│   React Dashboard: signal scores │ portfolio tracking │ trade alerts    │
│   quant_ai: RAG + Local LLM — natural language stock analysis           │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              ORCHESTRATION LAYER (Airflow, host-based) — 14 DAGs        │
│                                                                           │
│   Scheduled (7)                          Manual / on-demand (7)         │
│   */30min  quant_intraday_news           backfill_1_gdelt_collect       │
│   06:30 d. price_history_backfill          → backfill_2_company_match   │
│   07:30 d. daily_signal_pipeline             → backfill_3/4_llm_enrich  │
│   20:30 d. quant_retail_sentiment              → backfill_5_snorkel     │
│   04:00 Su gdelt_batch_verify                    → backfill_6_features  │
│   06:00 Su weekly_inst13f_holdings       quant_news_validation          │
│   07:00 Su weekly_model_training           (quality audit report)       │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Key Results

| Metric | Value |
|--------|-------|
| Raw news data processed | **8TB+** (GDELT) |
| Articles labeled | **840K+** |
| Stock universe | **103 equities** (100 US + HXSCL OTC) |
| LLM agreement rate | **77.3%** (Gemma + Qwen) |
| Portfolio backtest Sharpe (20d, net of cost) | **0.77** (gross 0.92) vs SPY 0.54 |
| Portfolio backtest Sharpe (60d, net of cost) | **0.73** (gross 0.77) vs SPY 0.47 |
| Walk-forward Long-short annualized return | **+21.7%** |
| Walk-forward Long-short Sharpe | **0.85** |
| Hit rate | **63.6%** |
| Best single-factor IC (60d) | **+0.198** (`inst_holding_pct_chg`) |
| Docker microservices | **9 active** |

---

## Repositories

| Repo | Description | Tech |
|------|-------------|------|
| [quant_data](https://github.com/zhengtiantian/quant_data) | ML pipeline: LLM labeling, feature engineering, model training, backtesting | Python, LightGBM, Snorkel, Airflow |
| [quant_api](https://github.com/zhengtiantian/quant_api) | REST API backend: signal serving, portfolio tracking, Kafka publishing | Java 21, Spring Boot 3, Keycloak |
| [quant_ui](https://github.com/zhengtiantian/quant_ui) | Signal dashboard frontend | React, TypeScript, Vite |
| [quant_ai](https://github.com/zhengtiantian/quant_ai) | AI assistant: RAG + local LLM natural language stock analysis | Python, FastAPI, LM Studio |
| [ai-equity-signal-platform](https://github.com/zhengtiantian/ai-equity-signal-platform) | Platform deployment (this repo) | Docker Compose |

---

## Tech Stack

### Data & ML
`Python` `LightGBM` `Ridge Regression` `Snorkel` `Gemma 3B` `Qwen 4B` `LM Studio` `MLflow` `SHAP`

### Data Engineering
`Apache Airflow` `Apache Kafka` `MongoDB` `MySQL` `GDELT` `Finnhub API` `SEC EDGAR`

### Backend
`Java 21` `Spring Boot 3` `Keycloak` `REST API` `Kafka Producer/Consumer`

### Frontend & AI
`React` `TypeScript` `Vite` `RAG` `LM Studio` `FastAPI`

### Infrastructure
`Docker` `Docker Compose` `launchd` (host scheduler) `Multi-node work queue` (MySQL-backed, 2× MacBook workers + RTX 5090 inference node)

---

## Services (docker-compose)

| Service | Port | Description |
|---------|------|-------------|
| `quant_ui` | 18080 | React signal dashboard |
| `quant_api` | 18081 | Spring Boot REST API |
| `quant_keycloak` | 18082 | Auth server |
| `mongo6` | 37018 | MongoDB (840K articles, feature store) |
| `mysql8` | 23306 | MySQL (workflow, user data) |
| `airflow-webserver` | 15060 | Airflow DAG management |
| `mlflow` | 15050 | Experiment tracking |
| `kafka` | — | Signal event streaming |
| `kafka-ui` | 15070 | Kafka topic management |
| `quant-ai` | 18000 | RAG + LLM assistant (runs as host process; container for reference) |

> **Note:** `quant_ai` runs as a launchd host process (`com.quant.ai`) on port 18000 rather than through Docker, because VPNKit TCP prevents containers from reaching the LM Studio model server on the host.

---

## Quick Start

### Prerequisites
- Docker Desktop (48GB+ RAM recommended — all LLMs run via LM Studio)
- [LM Studio](https://lmstudio.ai/) with the following models loaded:
  - `gemma3:4b` — news labeling Pass A
  - `qwen3:4b` — news labeling Pass B
  - `qwen3.5-9b-mlx` — quant_ai chat assistant
  - `nomic-embed-text` — quant_ai RAG embeddings

### Start All Services

```bash
git clone https://github.com/zhengtiantian/ai-equity-signal-platform.git
cd ai-equity-signal-platform
docker compose pull
docker compose up -d
```

### Start quant_ai (host process)

```bash
cd quant_ai
launchctl load ~/Library/LaunchAgents/com.quant.ai.plist
# or directly:
bash run_host.sh
```

### Access

| Service | URL | Credentials |
|---------|-----|-------------|
| Signal Dashboard | http://localhost:18080 | admin / admin |
| Airflow | http://localhost:15060 | admin / admin |
| MLflow | http://localhost:15050 | — |
| Kafka UI | http://localhost:15070 | — |
| quant_ai API | http://localhost:18000/docs | — |

---

## Roadmap

### Completed
- [x] Alt-data research layer (macro, retail, analyst, 13F, premarket)
- [x] Transaction cost model (commission + liquidity-tiered slippage)
- [x] Daily signal automation (launchd production scheduler)
- [x] Paper-trading position tracker + exit alerts
- [x] Data quality checks + factor analysis (IC decay, SHAP)
- [x] RAG + local LLM assistant (quant_ai)
- [x] Dynamic 4-regime weight switching (RISK_ON / NEUTRAL / STRESSED / RISK_OFF)
- [x] Volatility-adaptive stop-loss (2×vol_20d, clamped 4–12%) + rolling OOS IC monitor
- [x] ETL unit tests (90 tests, CI-enforced via GitHub Actions)
- [x] Stock universe expanded to 103 symbols (added STX / WDC / HXSCL)
- [x] Multi-node distributed workers — GDELT batch workers on multiple machines (MacBook Pro M5 Pro 48G + MacBook Pro M5) pull from a shared MySQL task queue (crash-safe retry, idempotent upserts); LLM/SLM inference offloaded to a dedicated GPU node (Ryzen 9800X + RTX 5090 + 96G, LM Studio)
- [x] Airflow migration — 14 production DAGs on a host-based scheduler (macOS fork/setproctitle crash loop fixed), running live: 7 on cron schedule (intraday news, daily signal pipeline, price/retail/13F/model-training, weekly batch self-heal check) + 7 manual (split GDELT history backfill pipeline, news quality audit)
- [x] GDELT batch self-healing — weekly job re-derives each 'done' batch's expected files and reopens any with gaps missed by transient download failures (claim_next_batch never revisits 'done' batches on its own)

### Signal & Quant Research
- [ ] Rolling OOS IC signal quality dashboard — visualize IC trend over time in the React UI
- [ ] Beta neutralization + sector exposure limits for long-short portfolio
- [ ] Kafka end-to-end verified — signal→alert/position consumer chain defined but not yet proven live

### Signal Research Rigor (low priority — QR interview defense)
- [ ] **M.1** Point-in-time S&P 500 universe (incl. delisted) — remove survivorship/selection bias of the hand-picked tech list
- [ ] **M.2** PIT data hygiene audit — purge future-dated articles; verify signal-available-time vs data-creation-time across all features
- [ ] **M.3** IC significance — Newey-West t-stats, IC decay/half-life, per-year/per-regime stability tables
- [ ] **M.4** Sentiment orthogonalization — residual IC after neutralizing momentum/reversal/size/sector (does news add info beyond price?)
- [ ] **M.5** Overfitting defenses — untouched final holdout, experiment/trial registry, deflated Sharpe
- [ ] **M.6** Research report writeup — paper-style: hypothesis, method, results, failure cases, honest limitations

### Live Trading
- [ ] **Broker API integration (Alpaca)** — wire daily signals to real order execution; pre-trade guardrails: max 5% per position, daily loss kill-switch, whitelist-only symbols, fill reconciliation against paper positions; Stage 1 paper account → Stage 2 live with small capital

### AI Engineering — LLM / RAG
- [ ] **F.2** RAG upgrade (Qdrant) — replace MongoDB keyword search with vector similarity for quant_ai news Q&A
- [ ] **F.5** FinBERT fine-tuning — replace dual-LLM labeling pipeline with a single fine-tuned model (~200× speedup)
- [ ] **F.10** Strategy Studio → backtest execution — wire the natural-language strategy generator to the Python backtest engine
- [ ] **F.11** News pre-filter SLM — distilbert binary classifier before dual-LLM pass; eliminates ~70% irrelevant GDELT articles
- [ ] **F.12** Signal explanation generation — SLM generates plain-English "why this stock scored high" for each top signal
- [ ] **F.13** Morning briefing agent — 07:00 pre-market summary for held positions: overnight news, regime, exit warnings
- [ ] **F.14** Earnings surprise prediction — LLM aggregates pre-earnings signals → beat/miss probability factor
- [ ] **F.15** SEC EDGAR + earnings transcript RAG — 10-K/10-Q and earnings calls embedded in Qdrant for natural language queries
- [ ] **F.19** LLM factor hypothesis generator — LLM suggests new factor ideas from IC table + failure mode patterns

### AI Engineering — Agents
- [ ] **F.4** LangGraph multi-agent assistant — data_agent → analysis_agent → strategy_agent → risk_agent pipeline
- [ ] **F.8** Active learning agent — surface low-confidence labels for human review
- [ ] **F.9** Rule optimization agent — iterative LLM-judge loop that auto-improves news relevance rules (🟡 code written, not tested)
- [ ] **F.16** Real-time news monitoring agent — 30-min polling for held positions; instant alert on sentiment spike
- [ ] **F.17** Portfolio Manager Agent — signals + positions + regime → structured add/reduce/hold recommendation
- [ ] **F.18** Backtest reflection agent — auto-diagnose weak years (2022/2024) and generate hypothesis report
- [ ] **F.20** Dip-buy scanner agent — negative-news burst / earnings miss / drawdown on watchlist → LLM triages sentiment washout vs falling knife → contrarian entry candidates with reasoning

### MCP Integration
- [ ] **I.1** quant_mcp_server — signals, news, positions, factor IC, regime, backtest trigger as MCP tools
- [ ] **I.2** Claude Desktop integration — connect quant MCP server to Claude Desktop for natural language trading queries
- [ ] **I.3** Alpaca order execution via MCP — LLM-driven order placement with server-side risk guardrails
- [ ] **I.4** External data MCP tools — Finnhub / SEC EDGAR / yfinance as MCP tools for agent use
- [ ] **I.5** MCP inter-service communication — replace quant_ai → quant_api REST with MCP protocol

### Platform & Infrastructure
- [ ] **E.6** WebSocket real-time push — live signal scores streamed to the React dashboard
- [ ] **E.9** UI intraday price chart — TradingView Lightweight Charts + Alpaca bars API; entry/stop-loss overlay
- [ ] **E.10** Inference node health check + failover — probe the RTX 5090 GPU node (LM Studio) and auto-switch `SLM_API_URL` to the local Mac instance when it is unreachable; pass-through degradation stays as last resort
- [ ] **E.4** Kubernetes manifests — replace Docker Compose for production deployment

### Stock Universe
- [ ] **G.2** Phase 2–4 expansion — energy/materials, international ADRs (BABA/JD/SE), REITs/financials

See [quant_data/PROJECT_PLAN.md](https://github.com/zhengtiantian/quant_data/blob/main/PROJECT_PLAN.md) for detailed specs and effort estimates.
