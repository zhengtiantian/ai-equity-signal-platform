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
| Portfolio backtest Sharpe (20d, net of cost) | **0.77** (gross 0.92) vs SPY 0.54 |
| Portfolio backtest Sharpe (60d, net of cost) | **0.73** (gross 0.77) vs SPY 0.47 |
| Walk-forward Long-short annualized return | **+21.7%** |
| Walk-forward Long-short Sharpe | **0.85** |
| Hit rate | **63.6%** |
| Best single-factor IC (60d) | **+0.198** (`inst_holding_pct_chg`) |
| Platform services | **13 active** (11 Docker containers + 2 host processes) |

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

## Roadmap

Every item carries a stable ID shared with [PROJECT_PLAN.md](PROJECT_PLAN.md), which holds the
detailed spec and effort estimate for each. Checked items are shipped and running.

**Recent milestones:** manual holdings tracker with live quotes (P.1) · ReAct research
agent (F.21) · MCP server + Claude Desktop (I.1/I.2) · Airflow migration (10 DAGs) ·
multi-node distributed GDELT workers.

### Data & Pipeline
- [x] **D.1/D.2/D.4/D.7/D.8** Alt-data research layer — macro, retail, analyst, 13F, premarket
- [x] **C.1** Daily signal automation — now an Airflow DAG (originally a launchd job)
- [x] **C.4/C.5** Paper-trading position tracker + exit alerts
- [x] **C.7/C.9** Data quality checks + factor analysis report (IC decay, SHAP)
- [x] **C.8** ETL unit tests — 90 tests, CI-enforced via GitHub Actions
- [x] Airflow migration — 10 DAGs on a host-based scheduler (macOS fork/setproctitle crash loop fixed): 7 on cron (intraday news, daily signal pipeline, price/retail/13F/model training, weekly batch self-heal) + 3 manual (2-stage news backfill, quality audit)
- [x] GDELT batch self-healing — weekly job re-derives each 'done' batch's expected files and reopens any with gaps left by transient download failures
- [x] Multi-node distributed workers — GDELT batch workers on multiple machines pull from a shared MySQL task queue (crash-safe retry, idempotent upserts); LLM/SLM inference offloaded to a dedicated GPU node (RTX 5090, LM Studio)

### Signal & Quant Research
- [x] **H.1** Transaction cost model — commission + liquidity-tiered slippage
- [x] **H.2** Dynamic 4-regime weight switching — RISK_ON / NEUTRAL / STRESSED / RISK_OFF
- [x] **H.3** Volatility-adaptive stop-loss (2×vol_20d, clamped 4–12%) + rolling OOS IC monitor
- [ ] **H.4** Rolling OOS IC dashboard — visualise the IC trend over time in the React UI
- [ ] **B.1** Long-short portfolio enhancement — beta neutralization, sector exposure limits
- [x] **Stage 7** Kafka end-to-end verified — publishing 20 signals advanced the consumer offsets across all four partitions with zero lag and the consumer logged the deserialized events. Getting there required fixing a consumer that could not deserialize its own producer's records (the producer omits Spring type headers by design) and, lacking an `ErrorHandlingDeserializer`, re-read the same offset forever at 100% CPU
- [ ] **Stage 7 (remaining)** Execution-log API — surface DAG/task run history through the REST API

### Signal Research Rigor (QR interview defense)
- [ ] **M.1** Point-in-time S&P 500 universe (incl. delisted) — removes the survivorship/selection bias of the hand-picked tech list
- [ ] **M.2** PIT data hygiene audit — purge future-dated articles (the corpus contains GKG rows dated 2028–2037) and verify signal-available-time vs data-creation-time across all features
- [ ] **M.3** IC significance — Newey-West t-stats, IC decay/half-life, per-year and per-regime stability tables
- [ ] **M.4** Sentiment orthogonalization — residual IC after neutralizing momentum/reversal/size/sector: does news add information beyond price?
- [ ] **M.5** Overfitting defenses — untouched final holdout, experiment/trial registry, deflated Sharpe
- [ ] **M.6** Research report writeup — paper-style: hypothesis, method, results, failure cases, honest limitations

### Portfolio & Live Trading
- [x] **P.1** Manual holdings tracker — the only positions the platform knew about were synthetic: `track_positions.py` mechanically opens the day's top-5 signals, so there was nowhere to record what is actually held. **Transactions are the source of truth and holdings are derived** — storing a holding row with an `avgCost` field makes it unmaintainable, because editing the quantity leaves no way to recompute what the average should now be. `portfolio_transactions` (symbol, side, quantity, price, tradeDate, fee, note) with full CRUD so any mis-keyed trade can be corrected, plus a freely editable `portfolio_cash` balance; quantity, running weighted-average cost, unrealised and realised P&L, and weight as a share of *total* capital are folded from the log on read. Live quotes from Finnhub behind a 20s TTL cache (60 req/min free tier cannot survive a page polling 20 symbols), stretched off-hours, falling back to the last `stock_prices_history` close and labelling it as such rather than passing a stale number off as live. Surfaces: `/api/portfolio/*` on quant_api, a "My Holdings" tab in quant_ui, and `get_my_holdings` / `get_my_transactions` MCP tools — which makes the portfolio readable by Claude Desktop, Codex, and quant_ai's agent at once. 10 unit tests cover the money maths on a pure `replay()` fold (average cost after mixed buys, realised P&L against the average *at the time of sale*, full exit and re-entry, capped overselling). Prerequisite for F.17 and G.1 — neither position sizing nor a 5%-per-position guardrail means anything measured against a portfolio nobody owns. Holdings are personal financial data: they stay in the local database and never reach a seed file, fixture, or commit.
- [ ] **G.1** Broker API integration (Alpaca) — wire daily signals to real order execution; pre-trade guardrails: max 5% per position, daily loss kill-switch, whitelist-only symbols, fill reconciliation against paper positions; Stage 1 paper account → Stage 2 live with small capital

### AI Engineering — LLM / RAG
- [ ] **F.2** Persistent vector store (Qdrant) — quant_ai currently embeds its knowledge folder into an in-memory numpy index rebuilt on every start; move to Qdrant so news and filings can be searched at corpus scale
- [ ] **F.5** FinBERT fine-tuning — replace the dual-LLM labeling pipeline with a single fine-tuned model (~200× inference speedup)
- [ ] **F.10** Strategy Studio → backtest execution — wire the natural-language strategy generator to `backtest_portfolio.py` so generated strategies produce real Sharpe / drawdown numbers
- [ ] **F.11** Fast news pre-filter — an LLM relevance filter already runs ahead of the dual-LLM pass (`slm_filter.py`); replace it with a distilbert binary classifier for throughput, since relevance judgement does not need a 4B model
- [ ] **F.12** Signal explanation generation — SLM writes a two-sentence "why this stock scored high" for each top signal, shown inline in SignalsPanel
- [ ] **F.14** Earnings surprise prediction — in the 10-day pre-earnings window, aggregate news sentiment + analyst consensus into a beat/miss probability factor
- [ ] **F.15** SEC EDGAR + earnings transcript RAG — 10-K/10-Q risk sections and earnings calls embedded for natural language queries over filing content
- [ ] **F.19** LLM factor hypothesis generator — prompt the model with the current IC table + failure modes to suggest new factor ideas for human review

### AI Engineering — Agents
- [x] **F.21** Single-agent ReAct research loop — hand-written tool-calling loop on local qwen3.5-9b; read-only platform tools through `quant_api /api/agent-data/*` with mongo fallback; guardrails (per-step dedupe, cross-step cache, max-steps cap, thinking-model content fallback) covered by unit tests; SSE streaming into the React "AI Agent" tab
- [ ] **F.4** Multi-agent assistant — sentiment/fundamental/technical specialists feeding an orchestrator; extends the shipped F.21 loop (LangGraph optional)
- [ ] **F.6** Rule validator agent — interactive rule-debugging loop on top of F.21 (🟡 `tools/rule_validator_agent.py` written, not tested)
- [ ] **F.7** Airflow adaptive scheduling agent — adjust collection windows from data-quality metrics
- [ ] **F.8** Active learning agent — surface low-confidence LLM labels for human review; closes the annotation feedback loop
- [ ] **F.9** Rule optimization agent — sample → LLM judge → diagnose FP/FN → modify rules (🟡 `tools/rule_optimizer.py` written, not tested)
- [ ] **F.13** Morning briefing agent — 07:00 pre-market summary for held positions: overnight news, regime, exit warnings
- [ ] **F.16** Real-time news monitoring agent — 30-minute polling for held positions; alerts on a sentiment spike or negative event cluster
- [ ] **F.17** Portfolio Manager agent — a **review layer over the rule engine**, not a replacement for it. `track_positions.py` already decides entries, exits, and stops deterministically; an LLM would be both worse and non-reproducible at that job. The agent instead reviews each rule decision against what rules structurally cannot see: the news behind a price move (a stop triggered by a sector-wide selloff that has already reversed is a whipsaw, not a signal), and portfolio-level facts no per-position rule considers (sector concentration, total exposure against the current regime). Output is a machine-consumable decision table — `agree` / `flag` per action with `target_weight_pct` and cited evidence — so it can later drive G.1 execution.
Three deterministic gates run after the model replies: JSON schema (one repair round-trip, then fail loudly), **grounding** (every cited `(tool, field, value)` must appear in a real observation from this run, so fabricated numbers are dropped rather than prayed against), and business rules (whitelist, ≤5% per position, exit only what is held). Depends on P.1.
- [ ] **F.22** Agent evaluation harness — golden cases in `eval/cases.yaml` plus a report. Whether a recommendation *makes money* cannot be scored without waiting for the market; what can be scored are the failure modes that actually keep agents out of production: schema validity rate, **grounding rate** (fraction of cited evidence that is real), tool precision/recall against the tools a case requires, run-to-run stability (Jaccard overlap across N runs of one input), and cost in steps and latency. The rule engine doubles as the baseline — the agent's job is not to differ from it, but to be justifiably different when it does.
- [ ] **F.18** Backtest reflection agent — auto-diagnose weak-year IC failures (2022/2024) and generate a hypothesis report
- [ ] **F.20** Dip-buy scanner agent — negative-news burst / earnings miss / drawdown on the watchlist → triage sentiment washout vs falling knife → contrarian entry candidates with reasoning

### MCP Integration
- [x] **I.1** MCP server (`quant_ai/mcp_server.py`) — eight read-only MCP tools (news sentiment, features, ranked signals, rule-generated positions, the user's own holdings and trade log, backtest performance, universe) over stdio, served through the `quant_api` layer
- [x] **I.2** Claude Desktop integration — registered in `claude_desktop_config.json`, verified end-to-end over the real MCP protocol
- [ ] **I.3** Alpaca order execution via MCP — order tools behind server-side pre-trade guardrails, so agents trade through the same interface
- [ ] **I.4** External data MCP tools — Finnhub / SEC EDGAR / yfinance wrapped as MCP tools so agents decide what to fetch
- [ ] **I.6** `search_news` — full-text search over the 845K labeled articles, filterable by symbol and date, returning headline, date, sentiment and source. The largest gap in the current surface: every existing tool returns a pre-computed aggregate, so a client can learn that a symbol averaged +0.31 sentiment but cannot read a single article behind it. Turns the server from something that reports conclusions into something that can be interrogated.
- [ ] **I.7** `get_feature_history` — feature time series for a symbol (selected fields, N days). `get_stock_features` returns only the latest row, so "is sentiment improving or deteriorating" is currently unanswerable.
- [ ] **I.8** `screen_universe` — screen the 100-symbol universe by feature thresholds (e.g. positive momentum with deteriorating sentiment), so the client can pose its own question instead of only consuming rankings the platform chose.
- [ ] **I.9** `get_factor_performance` — per-factor IC by year and horizon from the stability analysis; the evidence behind *why* a signal ranks where it does.
- [ ] **I.10** Secondary tools — `compare_symbols` (convenience over two calls), `get_pipeline_status` (data freshness, last DAG run), `search_gkg` (675M-row GKG inverted index).
- [ ] **I.11** Codex CLI as a third MCP client — register the same `mcp_server.py` alongside Claude Desktop and quant_ai's agent. Config only, no new code: the point of the stdio server is that clients are free.
- [x] **I.5** MCP inter-service communication — quant_ai's research agent is now an MCP client (`mcp_client.py`) that discovers its tool surface from `mcp_server.py` over stdio instead of implementing tools itself. The MCP server became the single tool definition (and was folded into quant_ai, since the dependency conflict that had justified a separate project was gone), the agent went from 2 tools to 6 without new agent code, and 139 lines of duplicated tool/mongo/REST logic came out of `agent.py`

### Platform & Infrastructure
- [x] **E.2** CI/CD GitHub Actions — tests and image builds run on every push
- [x] **E.7** Root README + architecture diagram
- [ ] **E.4** Kubernetes manifests — replace Docker Compose for production deployment
- [ ] **E.6** WebSocket real-time push — stream live signal scores to the dashboard instead of polling
- [ ] **E.9** UI intraday price chart — TradingView Lightweight Charts + Alpaca bars API, entry/stop-loss overlay per position; no hourly data stored locally
- [ ] **E.10** Inference node health check + failover — probe the RTX 5090 GPU node and auto-switch `SLM_API_URL` to the local Mac instance when unreachable; pass-through degradation as last resort

### Stock Universe
- [x] Universe at 100 US symbols — STX / WDC / HXSCL were added to the watchlist but carry no usable news or features, so they are excluded from the reported universe
- [ ] **G.2** Phase 2–4 expansion — energy/materials (XOM, CVX, NEE, LIN, APD), international ADRs (BABA, JD, PDD, SE), then REITs/financials
