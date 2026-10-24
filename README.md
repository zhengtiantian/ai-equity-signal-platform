# AI-Driven Equity Signal Platform

An end-to-end quantitative research and signal generation platform that processes financial news through LLM pipelines to produce daily equity trading signals across 100 US stocks.

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
│   SLM company match ──▶  Pass A: Gemma 3B  ──┐                          │
│                                               ├──▶ merge (77.3% agr.)   │
│                          Pass B: Qwen 4B   ──┘                          │
│                                    │                                     │
│                       llm_sentiment_final / event_type                  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ 845K labeled articles
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
│   → 189K+ rows │ 100 symbols │ 7 return horizons (5–60d)               │
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
│   Spring Boot REST API (Keycloak JWT, deny-by-default)                                   │
│   React Dashboard: signal scores │ portfolio tracking │ trade alerts    │
│   quant_ai: ReAct tool-calling research agent + RAG stock Q&A           │
│   quant_ai/mcp_server.py: MCP (stdio) — platform tools for any client   │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              ORCHESTRATION LAYER (Airflow, host-based) — 10 DAGs        │
│                                                                           │
│   Scheduled (7)                          Manual / on-demand (3)         │
│   */30min  quant_intraday_news           backfill_1_collect_and_match   │
│   06:30 d. price_history_backfill          (GDELT ⟶ SLM company match)  │
│   07:30 d. daily_signal_pipeline                                        │
│   20:30 d. quant_retail_sentiment        backfill_2_enrich_and_features │
│   04:00 Su gdelt_batch_verify              (LLM A/B ⟶ merge ⟶ features) │
│   06:00 Su weekly_inst13f_holdings       quant_news_validation          │
│   07:00 Su weekly_model_training           (quality audit report)       │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Key Results

| Metric | Value |
|--------|-------|
| Raw news data processed | **13TB** (GDELT GKG, 2016→present) |
| Articles labeled | **845K+** |
| Stock universe | **100 US equities** |
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
| Platform services | **13 active** (11 Docker containers + 2 host processes) |

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
> **0.69 is still an upper bound.** M.1 has not been done: the 100-symbol universe was
> hand-picked in 2026 and backtested from 2016, so it consists of names that survived and
> did well. That selection bias is very likely worth more than the 0.09 just removed, and
> until it is closed no figure here should be read as an achievable return.
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
| [quant_data](https://github.com/zhengtiantian/quant_data) | ML pipeline: LLM labeling, feature engineering, model training, backtesting | Python, LightGBM, Airflow |
| [quant_api](https://github.com/zhengtiantian/quant_api) | REST API backend: signal serving, portfolio tracking, Kafka publishing | Java 21, Spring Boot 3, Keycloak |
| [quant_ui](https://github.com/zhengtiantian/quant_ui) | Signal dashboard frontend | React, TypeScript, Vite |
| [quant_ai](https://github.com/zhengtiantian/quant_ai) | AI interface: ReAct research agent, RAG stock Q&A, and the platform's MCP server | Python, FastAPI, MCP SDK, LM Studio |
| [ai-equity-signal-platform](https://github.com/zhengtiantian/ai-equity-signal-platform) | Platform deployment (this repo) | Docker Compose |

---

## Tech Stack

### Data & ML
`Python` `LightGBM` `Ridge Regression` `Gemma 3B` `Qwen 4B` `LM Studio` `MLflow` `SHAP`

### Data Engineering
`Apache Airflow` `Apache Kafka` `MongoDB` `MySQL` `GDELT` `Finnhub API` `SEC EDGAR`

### Backend
`Java 21` `Spring Boot 3` `Keycloak` `REST API` `Kafka Producer/Consumer`

### Frontend & AI
`React` `TypeScript` `Vite` `RAG` `ReAct Agent` `Function Calling` `SSE Streaming` `LM Studio` `FastAPI`

### Infrastructure
`Docker` `Docker Compose` `launchd` (host scheduler) `Multi-node work queue` (MySQL-backed, 2× MacBook workers + RTX 5090 inference node)

---

## Services (docker-compose)

| Service | Port | Description |
|---------|------|-------------|
| `quant_ui` | 18080 | React signal dashboard |
| `quant_api` | 18081 | Spring Boot REST API |
| `quant_keycloak` | 18082 | Auth server |
| `mongo6` | 37018 | MongoDB (845K articles, feature store) |
| `mysql8` | 23306 | MySQL (workflow, user data) |
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

## Project Plan

The roadmap, current status and the detailed spec of every item are in [PROJECT_PLAN.md](PROJECT_PLAN.md).
