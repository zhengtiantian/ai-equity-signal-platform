# AI-Driven Equity Signal Platform

An end-to-end quantitative research and signal generation platform that processes financial news through LLM pipelines to produce daily equity trading signals across 100 US stocks.

## Platform Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA COLLECTION LAYER                             │
│         GDELT (8TB+) │ Finnhub │ NewsAPI │ Yahoo Finance                │
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
│                                                                           │
│   → 134K rows │ 100 symbols │ 7 return horizons (5–60d)                 │
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
│   LangChain Agent + Qdrant RAG: natural language stock analysis         │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       ORCHESTRATION LAYER (Airflow)                      │
│                                                                           │
│   05:00  gdelt_backfill ─┐                                               │
│          finnhub_news   ─┼──▶ price_update ──▶ feature_build            │
│          yahoo_news     ─┘                                               │
│   09:00  llm_pass_a ─┐                                                  │
│          llm_pass_b ─┼──▶ snorkel_merge ──▶ feature_rebuild             │
│   weekly model_training                                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Key Results

| Metric | Value |
|--------|-------|
| Raw news data processed | **8TB+** (GDELT) |
| Articles labeled | **840K+** |
| Stock universe | **100 US equities** |
| LLM agreement rate | **77.3%** (Gemma + Qwen) |
| Walk-forward Long-short annualized return | **+21.7%** |
| Long-short Sharpe ratio | **0.85** |
| Hit rate | **63.6%** |
| Best single-factor IC (60d) | **0.064** (`surprise_pct_last`) |
| Docker microservices | **22** |

---

## Repositories

| Repo | Description | Tech |
|------|-------------|------|
| [quant_data](https://github.com/zhengtiantian/quant_data) | ML pipeline: LLM labeling, feature engineering, model training, backtesting | Python, LightGBM, Snorkel, Airflow |
| [quant_api](https://github.com/zhengtiantian/quant_api) | REST API backend: signal serving, backtest orchestration, Kafka publishing | Java 17, Spring Boot 3, Keycloak |
| [quant_ui](https://github.com/zhengtiantian/quant_ui) | Signal dashboard frontend | React, Redux Toolkit, Material-UI |
| [quant_langchain](https://github.com/zhengtiantian/quant_langchain) | AI agent service: RAG news search, workflow generation | Python, LangChain, Qdrant |
| [ai-equity-signal-platform](https://github.com/zhengtiantian/ai-equity-signal-platform) | Platform deployment (this repo) | Docker Compose, 22 services |

---

## Tech Stack

### Data & ML
`Python` `LightGBM` `Ridge Regression` `Snorkel` `Gemma 3B` `Qwen 4B` `Ollama` `MLflow` `SHAP`

### Data Engineering
`Apache Airflow` `Apache Kafka` `MongoDB` `MySQL` `Qdrant` `GDELT` `Finnhub API`

### Backend
`Java 17` `Spring Boot 3` `Keycloak` `REST API` `Kafka Producer/Consumer`

### Frontend & AI
`React` `Redux Toolkit` `LangChain` `RAG` `Dify`

### Infrastructure
`Docker` `Docker Compose` `22 microservices`

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
| `qdrant` | — | Vector store (RAG) |
| `langchain-agent` | 18000 | LangChain AI agent |
| `dify-web` | 18089 | Dify AI workflow UI |
| + 10 more | — | Postgres, Redis, RabbitMQ, Sandbox... |

---

## Quick Start

### Prerequisites
- Docker Desktop (16GB+ RAM recommended)
- Ollama with `gemma3:4b` and `qwen3:4b` models

### Start All Services

```bash
git clone https://github.com/zhengtiantian/ai-equity-signal-platform.git
cd ai-equity-signal-platform
docker compose pull
docker compose up -d
```

### Access

| Service | URL | Credentials |
|---------|-----|-------------|
| Signal Dashboard | http://localhost:18080 | admin / admin |
| Airflow | http://localhost:15060 | admin / admin |
| MLflow | http://localhost:15050 | — |
| Kafka UI | http://localhost:15070 | — |

### Run Research Pipeline

```bash
git clone https://github.com/zhengtiantian/quant_data.git
cd quant_data && python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Feature build
python research/daily_symbol_features.py

# Train models (walk-forward, all horizons)
python research/train_baseline_models.py --target all

# Factor analysis: IC decay + SHAP + Long-short
python research/factor_analysis.py --parts ic shap ls

# Backtest with risk metrics
python research/backtest_news_factor.py \
  --collection daily_symbol_features_company_matched_v2 \
  --horizons 20 60 --strategies top long_short
```

---

## Roadmap

- [ ] Transaction cost model (commission + slippage)
- [ ] Market regime detection (VIX-based signal filtering)
- [ ] Paper trading engine with OOS validation
- [ ] LangGraph multi-agent research assistant
- [ ] FinBERT fine-tuning (200× inference speedup)

See [quant_data/PROJECT_PLAN.md](https://github.com/zhengtiantian/quant_data/blob/main/PROJECT_PLAN.md) for full roadmap.
