# AI-Driven Equity Signal Platform

A self-hosted equity research platform that reads financial news with local LLMs, turns it into
point-in-time signals, and uses them — with prices, earnings and alternative data — for stock
ranking, event-driven strategy research and daily decisions on a real portfolio. Every model
runs on one Mac; every reported number is out of sample and comes with its failure cases.

## What It Does

| Area | What is built | In numbers |
|---|---|---|
| **News intelligence** | GDELT (13 TB of GKG) plus Finnhub / NewsAPI / Yahoo every 30 minutes; per-company matching rules with an SLM check; syndication dedupe; weekly keyword refresh reviewed in the UI | 885K labelled core articles; 490 point-in-time S&P 500 / Nasdaq-100 companies, news from 2018 (~743K articles crawled, ~661K with a body) |
| **Local LLM labelling and distillation** | Dual-LLM labels (event type, sentiment −1…1, strength) on title + 500 characters; teacher self-consistency as the pass line; distillation into small students, judged on the daily features they produce | Teacher 1.15 articles/s → students 18–108 articles/s (Qwen3-0.6B / 1.7B LoRA on MLX, ModernBERT-large) |
| **Quant research** | Feature store, Ridge + LightGBM ranking with walk-forward fitted weights, an event-strategy lab (CatBoost champion, LightGBM shadow, deflated Sharpe, MLflow), earnings pulse on 1-minute bars, Action RL | 189K+ feature rows × 7 horizons; look-ahead and syndication leaks found and removed (see Key Results) |
| **Decision support** | Holdings from the trade log, a portfolio risk gate, a daily action per holding (English / Chinese), upcoming catalysts, market briefs, indices against the last close, a phone page | Advice three times per trading day; every call logged and scored |
| **AI layer** | Hybrid retrieval (MongoDB text + Qdrant dense, RRF) with cross-encoder rerank, cited answers that refuse without evidence, a hand-written ReAct agent whose tools come from the MCP server, prompt-injection defence at the MCP boundary | Rerank +0.076 nDCG; judge agreement kappa 0.41 → 0.67; injection false positives 3 in 40,000 |

## Platform Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA COLLECTION LAYER                             │
│         GDELT (13TB) │ Finnhub │ NewsAPI │ Yahoo Finance │ FMP          │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ raw news
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       NLP / LLM LABELING LAYER                           │
│                                                                           │
│   SLM company match ──▶  Pass A: Gemma-4-E4B ┐                          │
│                                               ├──▶ merge (77.3% agr.)   │
│                          Pass B: Qwen3.5-9B ─┘                          │
│                                    │                                     │
│                       llm_sentiment_final / event_type                  │
│   Distilled students (in validation): Qwen3-0.6B/1.7B, ModernBERT-large │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ 885K labeled articles
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      FEATURE ENGINEERING LAYER                           │
│                                                                           │
│   News:  article_count, news_burst_20d, quality_score, full_ratio       │
│   LLM:   avg_sentiment_3d/5d, sentiment_shift_5d, high_signal_count     │
│   Earn:  surprise_pct_last, days_to_earnings, earnings_recency_weight   │
│   Price: past_ret_20d/60d, volatility_20d/60d, volume_shock_20d         │
│   Alt:   macro_*, retail_*, analyst_*, ah_gap/pm_gap                    │
│                                                                           │
│   → 189K+ rows │ core universe │ 7 return horizons (5–60d)             │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          ML MODEL LAYER                                   │
│                                                                           │
│   Ridge ──┐                                                              │
│           ├──▶ Ensemble ──▶ Walk-forward (retraining, see M.7)          │
│   LightGBM┘               Portfolio 20d net Sharpe 0.58 vs SPY 0.54     │
│                                                                           │
│   MLflow: experiment tracking │ SHAP: feature importance                │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ daily signals
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       SERVING / PLATFORM LAYER                           │
│                                                                           │
│   Kafka ──▶ signal distribution ──▶ alerts / position tracking          │
│   Spring Boot REST API (Keycloak JWT, deny-by-default)                  │
│   React Dashboard: Quant Model │ Holdings + daily action │ Briefs       │
│   quant_ai: holdings, risk gate, daily action, catalysts, briefs        │
│   quant_ai: hybrid RAG (Mongo text + Qdrant, rerank) + ReAct agent      │
│   quant_ai/mcp_server.py: MCP (stdio) — 12 tools for any client         │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│               ORCHESTRATION LAYER (Airflow, host-based) — 14 DAGs       │
│                                                                         │
│  Scheduled (11, UTC)                    Nightly chain / manual          │
│  */30min  quant_intraday_news           04:00 backfill_1 (collect+match)│
│  06:30 d. price_history_backfill          GDELT -> SLM company match    │
│  wkdy x3  daily_advice                  -> backfill_2 (enrich, features)│
│  21:15 wd market_snapshots                LLM A/B -> merge -> features  │
│  20:30 d. quant_retail_sentiment        -> daily_signal_pipeline        │
│  04:00 Su gdelt_batch_verify            quant_news_validation (manual)  │
│  06:00 Su weekly_inst13f_holdings                                       │
│  07:00 Su weekly_model_training                                         │
│  Sat/hr   keyword_refresh_weekly/_apply                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Key Results

| Metric | Value |
|--------|-------|
| Raw news data processed | **13TB** (GDELT GKG, 2016→present) |
| Articles labeled | **885K** (core universe) |
| Stock universe | **~100-stock core** (signals) + **490** point-in-time S&P 500 / Nasdaq-100 companies (news) |
| LLM agreement rate | **77.3%** (Gemma + Qwen) |
| Portfolio backtest Sharpe (20d, net of cost) | **0.58** (gross 0.73) vs SPY 0.54 — *0.78 → 0.69 after the M.7 look-ahead fix, → 0.58 after the M.12 syndication fix* |
| Portfolio backtest Sharpe (60d, net of cost) | **0.60** (gross 0.65) vs SPY 0.47 — re-run 2026-07-30, no longer stale |
| Portfolio backtest max drawdown (20d, net) | **−39.6%** — *improved from −42.1%; the deduped signal is lower-return and lower-risk* |
| Walk-forward Ensemble Rank IC (60d) | **0.0523** aggregate — but **negative in 4 of 9 years**, see below |
| Walk-forward Long-short annualized return | **+17.1%** — *was +21.7% before M.7* |
| Walk-forward Long-short Sharpe | **0.58** — *was reported 0.85; the long leg alone is 0.81, see below* |
| Walk-forward short-leg contribution | **−0.03% annualized, Sharpe −0.00** — the short side adds nothing |
| Hit rate (20d portfolio, net) | **62.9%** |
| Best single-factor IC (60d) | ~~+0.198 (`inst_holding_pct_chg`)~~ — **withdrawn, contaminated by look-ahead (see M.7)**. The 13F holdings are stored without a date and broadcast to every historical trade date, so this factor was reading the present. Institutions accumulate what has already risen, which is precisely the spurious correlation that produces a high IC here. Removed from the feature set, the four regime weight dicts, and the model inputs; the backtest was re-run and cost 0.09 Sharpe. |
| Retrieval rerank (R.3) | **+0.076 nDCG** over hybrid fusion, significant under both LLM judges |
| LLM judge calibration (R.4) | Cohen's kappa **0.41 → 0.67** after fixing the 1/2 grade boundary |
| Prompt-injection guard (S.1) | **3 false positives in 40,000** real articles (0.0075%); reports, never withholds |
| Labelling throughput (3.5.5) | Teacher **1.15** articles/s → distilled students **18–108** articles/s |
| Platform services | **8 Docker containers + 3 host processes** in the always-on core |

> **Why the figures moved down again (2026-07-30).** M.12 found that GDELT ingests every
> site of a syndication network as a separate article — one McDonald's story appears **402
> times** with a byte-identical body across 402 `*.iheart.com` subdomains, so that symbol-day
> carried 412 rows for 11 distinct stories. Corpus-wide 16% of rows are syndicated copies,
> but the share runs **2.3% to 52.4% per symbol** and correlates with sector, so it distorted
> a cross-sectional rank rather than shifting a level. Deduplicating on `(symbol, date,
> title)` cost **0.074 net Sharpe** (0.654 → 0.580 on a controlled shadow comparison), and
> that 0.074 was being earned from an artifact of a news-ingestion quirk. Drawdown and win
> rate both *improved*.
>
> **The pattern worth noting, because it is now the second instance.** The ML walk-forward
> barely moved (60d Ensemble IC 0.0572 → 0.0549, inside noise) while the hand-weighted regime
> scorer lost 0.074 Sharpe — exactly as in M.7, where the models ignored a constant factor and
> the scorer had assigned it 0.5–1.2 by fiat. **Both times the damage from a contaminated
> factor landed on hand-calibrated weights rather than fitted ones**, because a tree or a
> ridge learns how much to trust a column from the data and a hand-set 0.9 does not.
>
> **Why some figures moved down (2026-07-29).** M.7 removed `inst_holding_pct_chg`, a factor
> that was reading the future: its 13F source stores one dateless row per symbol, broadcast
> to every trade date, so 79 of 100 symbols carried a single constant across all eight years
> — "who institutions were accumulating in 2026", applied to rows dated 2018. Re-running the
> backtest without it cost **0.09 Sharpe** (0.78 → 0.69 net), which is the honest measure of
> what the leak was worth. The strategy survives it and still beats SPY net of cost, so the
> remaining factors were carrying real signal rather than riding on the leak.
>
> **0.69 is still an upper bound.** The 100-symbol universe was hand-picked in 2026 and
> backtested from 2016, so it consists of names that survived and did well. The point-in-time
> universe that removes this bias (M.1) was built on 2026-11-03, but the backtest has not been
> re-run on it yet. That selection bias is very likely worth more than the 0.09 just removed,
> and until the re-run no figure here should be read as an achievable return.
>
> **The bigger problem the re-run exposed: the signal is not stable across years.** The
> ML path barely moved when the leaked factor was removed — 60d ensemble IC went 0.059 →
> 0.0563 — but the year-by-year breakdown behind that aggregate is:
>
> | 2018 | 2019 | 2020 | 2021 | 2022 | 2023 | 2024 | 2025 | 2026 |
> |---|---|---|---|---|---|---|---|---|
> | +0.037 | +0.136 | **+0.220** | −0.028 | **−0.122** | **+0.239** | −0.036 | +0.010 | −0.102 |
>
> **Four of nine years are negative**, and the aggregate is carried almost entirely by 2019,
> 2020 and 2023. An IC of 0.056 assembled from +0.24 and −0.12 is not a 0.056 signal; it is
> something that works in particular years and reverses in others, with no way to know in
> advance which kind of year you are in. The two best years are a recovery and a melt-up and
> the worst is a bear market, which is what a momentum or beta proxy looks like rather than
> news alpha. **M.3** (Newey-West t-stats, IC decay, per-regime stability) and **M.4**
> (residual IC after neutralising momentum/size/sector) are the tests that would settle it,
> and neither has been run.
>
> **The short leg does nothing.** The long-short re-run gives long +17.1% at Sharpe 0.81 and
> short −0.03% at Sharpe −0.00, so the spread Sharpe of 0.58 is the long leg diluted by a
> leg that neither earns nor hedges. In substance this is a long-only strategy wearing a
> long-short label, which also means **M.9 borrow costs would push the short leg net
> negative** — paying to hold something that returns zero. The previously reported 0.85 is
> closest to the long leg's 0.81, so it may have been the long leg mislabelled as the spread
> all along.
>
> **A separate bug the re-run surfaced:** `factor_analysis.py` reports max drawdown as
> −100.00% on every leg, and −99.99% / −98.50% / −93.77% year by year. A true −100% is total
> ruin, so these are not results. The cause is compounding overlapping forward returns —
> a 60-day forward return is recomputed every day, and chaining those as if they were
> sequential periods diverges to −100% regardless of the underlying performance. Drawdown
> figures from this script should not be quoted until it is fixed.
>
> Note also which path the leak actually damaged. The ML models barely used the constant
> factor — a tree or a ridge sees a column with no variance and largely ignores it. The
> hand-weighted regime scorer gave it 0.5–1.2 weight by fiat, and that is where the entire
> 0.09 Sharpe came from. Hand-set weights were more easily fooled than the models, because
> the models at least looked at the data.

---

## Repositories

| Repo | Description | Tech |
|------|-------------|------|
| [quant_data](https://github.com/zhengtiantian/quant_data) | Collection, LLM labelling, features, models, backtests, the Airflow DAGs (run by the host scheduler) | Python, LightGBM, CatBoost, Airflow |
| [quant_ai](https://github.com/zhengtiantian/quant_ai) | Portfolio advisor and daily action (`markets/`), hybrid RAG, ReAct agent, the MCP server | Python, FastAPI, Qdrant, MCP SDK, LM Studio |
| [quant_api](https://github.com/zhengtiantian/quant_api) | REST API: signals, positions, holdings, news, agent data; Kafka signal events | Java 21, Spring Boot 3, Keycloak |
| [quant_ui](https://github.com/zhengtiantian/quant_ui) | Dashboard: Quant Model, Holdings, Market Briefs, Positions, Task Monitor, Keywords | React, TypeScript, Vite |
| [quant_keycloak](https://github.com/zhengtiantian/quant_keycloak) | Identity: the `quant` realm and its import | Keycloak |
| [ai-equity-signal-platform](https://github.com/zhengtiantian/ai-equity-signal-platform) | Platform deployment, project plan, repository map (this repo) | Docker Compose |

---

## Tech Stack

### Data & ML
`Python` `LightGBM` `CatBoost` `Ridge Regression` `SHAP` `MLflow` `Gemma-4-E4B` `Qwen3.5-9B` `LM Studio` `MLX (LoRA distillation)` `ModernBERT` `PyTorch (MPS)`

### Data Engineering
`Apache Airflow` `Apache Kafka` `MongoDB` `PostgreSQL` `GDELT` `Finnhub API` `SEC EDGAR`

### Backend
`Java 21` `Spring Boot 3` `Keycloak` `REST API` `Kafka Producer/Consumer`

### Frontend & AI
`React` `TypeScript` `Vite` `Hybrid RAG (MongoDB text + dense, RRF)` `Cross-encoder rerank` `Qdrant` `ReAct Agent` `MCP` `Function Calling` `SSE Streaming` `FastAPI`

### Infrastructure
`Docker` `Docker Compose` `launchd` (host scheduler) `Multi-node work queue` (PostgreSQL-backed, 2× MacBook workers + RTX 5090 inference node)

---

## Services (docker-compose)

| Service | Port | Description |
|---------|------|-------------|
| `quant_ui` | 18080 | React dashboard |
| `quant_api` | 18081 | Spring Boot REST API |
| `quant_keycloak` | 18082 | Auth server |
| `mongo6` | 37018 | MongoDB (articles, labels, feature store, signals) |
| `qdrant` | 26333 | Vector index for news retrieval |
| `airflow-postgres` | 25432 | PostgreSQL (Airflow metadata, Keycloak, GDELT batch queue) |
| `airflow-webserver` | 15060 | Airflow DAG management |
| `mlflow` | 15050 | Experiment tracking |
| `kafka` | — | Signal event streaming |
| `kafka-ui` | 15070 | Kafka topic management |
| `quant-ai` | 18000 | ReAct research agent + RAG assistant (host process via launchd; container disabled by profile) |

> **Note:** `quant_ai` runs as a launchd host process (`com.quant.ai`) on port 18000 rather than through Docker, because VPNKit TCP prevents containers from reaching the LM Studio model server on the host.

---

## Quick Start

### Prerequisites
- Docker Desktop (48GB+ RAM recommended — all LLMs run via LM Studio)
- [LM Studio](https://lmstudio.ai/) with these models downloaded. They need not be loaded:
  each pipeline task loads the one it needs and unloads it afterwards
  (`quant_data/tools/lm_session.py`).
  - `qwen3.5-4b-mlx` — GDELT news filter and company matching
  - `gemma-4-e4b-it-mlx` — news labelling Pass A
  - `qwen3.5-9b-mlx` — news labelling Pass B, quant_ai news Q&A
  - `text-embedding-nomic-embed-text-v1.5` — RAG embeddings

### Start the Core Services

```bash
git clone https://github.com/zhengtiantian/ai-equity-signal-platform.git
cd ai-equity-signal-platform
docker compose pull
./scripts/core.sh          # login chain + what the daily pipeline needs; stops the rest
# or every service:
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

## Repository Layout

| Path | What it is |
|------|------------|
| `docker-compose.yml` | Every service of the platform; image tags are pinned by each repo's CI |
| `.env.example` | Variables the compose file expects (copy to `.env`) |
| `scripts/core.sh` | Starts the always-on core (login chain, Airflow metadata DB, Qdrant, MLflow) and stops the rest |
| `scripts/host_proxy.py` | Host-side HTTP(S) proxy so Docker can pull and build behind a VPN |
| `docker/airflow/` | Airflow image for the web UI and `airflow-init` (Dockerfile + vendored provider wheel) |
| `PROJECT_PLAN.md` | Roadmap, status and the detailed spec of every item |
| `docs/STRUCTURE.md` | Directory-by-directory map of all six repositories and where each part runs |

---

## Project Plan

The roadmap, current status and the detailed spec of every item are in [PROJECT_PLAN.md](PROJECT_PLAN.md).
