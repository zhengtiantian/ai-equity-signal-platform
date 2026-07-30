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
│   LightGBM┘               Portfolio 20d net Sharpe 0.69 vs SPY 0.54     │
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
| Portfolio backtest Sharpe (20d, net of cost) | **0.69** (gross 0.83) vs SPY 0.54 — *was 0.78 before the M.7 look-ahead fix* |
| Portfolio backtest Sharpe (60d, net of cost) | 0.73 (gross 0.77) vs SPY 0.47 — **stale, pending re-run** |
| Walk-forward Ensemble Rank IC (60d) | **0.0563** aggregate — but **negative in 4 of 9 years**, see below |
| Walk-forward Long-short annualized return | **+17.1%** — *was +21.7% before M.7* |
| Walk-forward Long-short Sharpe | **0.58** — *was reported 0.85; the long leg alone is 0.81, see below* |
| Walk-forward short-leg contribution | **−0.03% annualized, Sharpe −0.00** — the short side adds nothing |
| Hit rate (20d portfolio, net) | **62.9%** |
| Best single-factor IC (60d) | ~~+0.198 (`inst_holding_pct_chg`)~~ — **withdrawn, contaminated by look-ahead (see M.7)**. The 13F holdings are stored without a date and broadcast to every historical trade date, so this factor was reading the present. Institutions accumulate what has already risen, which is precisely the spurious correlation that produces a high IC here. Removed from the feature set, the four regime weight dicts, and the model inputs; the backtest was re-run and cost 0.09 Sharpe. |
| Platform services | **13 active** (11 Docker containers + 2 host processes) |

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

## Roadmap

Every item carries a stable ID shared with [PROJECT_PLAN.md](PROJECT_PLAN.md), which holds the
detailed spec and effort estimate for each. Checked items are shipped and running.

**Recent milestones:** manual holdings tracker (P.1) · ReAct research
agent (F.21) · MCP server + Claude Desktop (I.1/I.2) · Airflow migration (10 DAGs) ·
multi-node distributed GDELT workers.

**Current focus — the R-series (AI at scale).** Named interview feedback (2026-07-28) asked
for more depth on RAG and MCP at scale. Audited against what is built, that is fair on both
counts: MCP has ten tools but only stdio and nothing past `@mcp.tool()`, and the retrieval
layer is numpy cosine similarity over four markdown files (382 lines) while **845K
company-matched news articles sit in MongoDB with zero embeddings**. R.1–R.9 below close
that gap, and are ranked above everything else pending.

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

> **Two of these gate G.1, and the order matters.** M.7 is a confirmed look-ahead leak in
> the platform's best-performing factor, and M.1 is selection bias baked into the universe
> itself. Until both are closed, every reported Sharpe is an upper bound of unknown
> looseness. Wiring a contaminated signal to a live broker turns a methodology error into
> a cash loss, so **G.1 stays blocked on M.7 and M.1** regardless of how ready the
> execution plumbing looks.

- [x] **M.7** **13F look-ahead leak — fixed, factor removed.** `inst_13f_holdings` holds exactly 100 documents, one per symbol, with **no date, quarter, or filing-date field at all** — only `collectedAt`. `attach_inst13f_features()` then left-joins on symbol alone and, in its own words, *"broadcast[s] to all trade_dates"*. A feature row for 2018-03-15 therefore carries 2026 institutional holdings. This is not a diffuse rigor concern: `inst_holding_pct_chg` was the **best single factor at IC +0.198**, and it scores that well *because* it leaks — institutions accumulate what has already risen, so projecting today's holdings backwards manufactures exactly that correlation. Notably every other alt-data source in the same file is correct: `attach_analyst_features` joins on `YYYY-MM` and its docstring says *"avoids lookahead"*, retail carries symbol+date across 1,365 rows, macro carries dates across 16,369. Only 13F is broadcast. Fix requires historical 13F with filing dates (SEC EDGAR full-text search exposes them) joined as-of the filing date, not the reporting period — the 45-day statutory lag is the whole point. **Outcome: point-in-time 13F does not exist in the platform** — `inst_13f_raw` holds 595 rows across three quarters (2025-09 … 2026-03), with no filing-date field, against a feature store spanning 2016–2026. So the factor was removed rather than repaired, behind `ENABLE_INST13F_FEATURES` (default off) in all four places it reached: the feature join, the four regime weight dicts, the model input list, and the `inst_outflow` exit rule — which, being driven by a per-symbol constant, either fired for a symbol every single day or never, making it a permanent blacklist dressed as an exit signal. **Re-running the backtest cost 0.09 Sharpe: 0.78 → 0.69 net, gross 0.92 → 0.83.** That is the honest price of the leak, and the strategy survives it — still 0.69 against SPY's 0.54 net of cost, so the other factors were carrying real signal rather than riding along. Re-enabling requires backfilling filing-dated 13F from EDGAR and joining as-of the filing date, never the reporting period; the join seam is left in place so that becomes a flag rather than a rewrite. Walk-forward figures are retraining.
- [ ] **M.1** Point-in-time S&P 500 universe (incl. delisted) — removes the survivorship/selection bias of the hand-picked tech list
- [ ] **M.2** PIT data hygiene audit — purge future-dated articles (the corpus contains GKG rows dated 2028–2037) and verify signal-available-time vs data-creation-time across all features
- [ ] **M.3** IC significance — Newey-West t-stats, IC decay/half-life, per-year and per-regime stability tables
- [ ] **M.4** Sentiment orthogonalization — residual IC after neutralizing momentum/reversal/size/sector: does news add information beyond price?
- [ ] **M.5** Overfitting defenses — untouched final holdout, experiment/trial registry, deflated Sharpe
- [ ] **M.6** Research report writeup — paper-style: hypothesis, method, results, failure cases, honest limitations
- [ ] **M.10** 🔴 **Max-drawdown calculation is wrong — blocker on any drawdown claim.** `factor_analysis.py` reports −100.00% for the long leg, the short leg and the spread, and −99.99% / −98.50% / −93.77% year by year. A true −100% is total ruin, so these are not results but an artifact: a 60-day forward return is recomputed every trading day, and chaining overlapping returns as though they were sequential periods diverges toward −100% whatever the underlying performance. Either compound non-overlapping periods only, or build an equity curve from the actual rebalance schedule the way `backtest_portfolio.py` does — its −42% drawdown is plausible, which is the tell that the two scripts disagree about what a period is. Until fixed, no drawdown from the factor-analysis path may be quoted.
- [ ] **M.11** Short leg earns nothing — decide whether to keep it. The re-run gives long +17.1% at Sharpe 0.81 against short −0.03% at Sharpe −0.00, so the 0.58 spread Sharpe is the long leg diluted by a leg that neither earns nor hedges. This is a long-only strategy carrying a long-short label. Two honest resolutions: report long-only and say so, or make the short side actually work (B.1 beta neutralisation, sector limits, and a screen for names where the signal is genuinely negative rather than merely bottom-ranked). **M.9 makes this urgent** — adding borrow costs to a leg returning zero pushes it net negative, so the current framing is not just imprecise, it flatters the result.
- [ ] **M.8** Turnover and capacity reporting — the backtest prices a round trip per position (H.1) but never reports **how many round trips there are**. At a 5-day horizon fed by daily signals, turnover could be high enough that the cost model, though honest per trade, understates the total drag by a wide margin. Report annualised turnover, cost as a share of gross return, and the capital level at which the liquidity filter starts binding — a strategy that works at $50k and not at $5m is a different claim.
- [ ] **M.9** Short-side borrow costs — the long-short Sharpe of 0.85 charges commission and slippage on both legs but nothing for **carrying** the short: no borrow fee, no hard-to-borrow screen, no recall risk. On the names most likely to be shorted by a news-sentiment signal, borrow is exactly where it is expensive. Until this is modelled, the long-short number is optimistic by an unmeasured amount and the long-only figures are the more defensible ones to quote.

### Portfolio & Live Trading
- [x] **P.1** Manual holdings tracker — the only positions the platform knew about were synthetic: `track_positions.py` mechanically opens the day's top-5 signals, so there was nowhere to record what is actually held. **Transactions are the source of truth and holdings are derived** — storing a holding row with an `avgCost` field makes it unmaintainable, because editing the quantity leaves no way to recompute what the average should now be. `portfolio_transactions` (symbol, side, quantity, price, tradeDate, fee, note) with full CRUD so any mis-keyed trade can be corrected, plus a freely editable `portfolio_cash` balance; quantity, running weighted-average cost, unrealised and realised P&L, and weight as a share of *total* capital are folded from the log on read. Live quotes from Finnhub behind a 20s TTL cache (60 req/min free tier cannot survive a page polling 20 symbols), stretched off-hours, falling back to the last `stock_prices_history` close and labelling it as such rather than passing a stale number off as live. **Under the VPN the containerised quant_api has no outbound internet at all** — the same constraint that forces quant_ai to run as a host process — so the deployed page serves daily closes and says so; live quotes work when quant_api runs on the host. Fetching quotes from the host Airflow scheduler into mongo would fix this properly (see G.4). Surfaces: `/api/portfolio/*` on quant_api, a "My Holdings" tab in quant_ui, and `get_my_holdings` / `get_my_transactions` MCP tools — which makes the portfolio readable by Claude Desktop, Codex, and quant_ai's agent at once. 10 unit tests cover the money maths on a pure `replay()` fold (average cost after mixed buys, realised P&L against the average *at the time of sale*, full exit and re-entry, capped overselling). Prerequisite for F.17 and G.1 — neither position sizing nor a 5%-per-position guardrail means anything measured against a portfolio nobody owns. Holdings are personal financial data: they stay in the local database and never reach a seed file, fixture, or commit.
- [ ] **G.4** Intraday quote collector — a host Airflow task polling Finnhub into an `intraday_quotes` collection every few minutes during US market hours, with quant_api reading mongo instead of calling out. Containers have no outbound internet under the VPN, so P.1's live-quote path only works when quant_api runs on the host; moving the fetch to the host scheduler (which does have internet, and already owns every other collector) makes live prices work in the deployed stack and removes the per-request rate-limit pressure at the same time.
- [ ] **G.1** Broker API integration (Alpaca) — **blocked on M.7 and M.1**: wiring a signal contaminated by look-ahead to a live broker converts a methodology error into a cash loss, and no amount of pre-trade guardrail protects against a factor that was reading the future. Wire daily signals to real order execution; pre-trade guardrails: max 5% per position, daily loss kill-switch, whitelist-only symbols, fill reconciliation against paper positions; Stage 1 paper account → Stage 2 live with small capital

### AI at Scale — RAG & MCP depth (R-series, current focus)

The honest starting position: the retrieval layer is `SimpleVectorStore` in `quant_ai/main.py` — numpy cosine similarity over the four markdown files in `knowledge/`, **382 lines of text**, re-embedded into process memory on every startup, falling back to keyword token overlap when the embedding endpoint is unreachable. No chunking, no reranking, no hybrid retrieval, no retrieval metric ever computed. Meanwhile **845K company-matched news articles sit in MongoDB with zero embeddings**. On the MCP side: ten tools, three clients, but stdio only and nothing past `@mcp.tool()` — no resources, prompts, sampling, elicitation, or auth, and all of it Python. The gap is not the concepts; it is that the rarest asset in a RAG interview — a large dated domain corpus with entity labels — was already collected and left unindexed while the demo ran on four README-sized files.

- 🟡 **R.1** Qdrant + embedding pipeline over the news corpus — **qdrant deployed** (`v1.18.3`, storage bind-mounted to the external drive rather than the container layer, 2 GB memory cap, log rotation: the 584G and 103G disk-full incidents both came from unbounded container growth, and a vector index would repeat that exactly). Corpus measured on 851,071 documents before writing any pipeline, which corrected both assumptions the plan had been carrying: only **30.2% of articles fit a single 512-token window** (median body 2,956 chars), so full chunking is **2.96M vectors / 9.1 GB / 20.0 h**, not the 2.6 GB estimated; and **17.90% (152,332) have no body at all**, making title-only one document in six rather than an edge case. Also found: **121,970 duplicates (14.3%)** on `(symbol, title, date)`, which would have consumed top-k slots and inflated every recall number R.4 produces. Measured throughput of `nomic-embed-text` (768-dim, local): **title+lede 74.2 vec/s → 3.19 h for the full corpus; 512-token chunks 41.1 vec/s → 20.0 h**. The transferable finding is that throughput is **character-bound, not request-bound** — every configuration held 66–74 Kchar/s, and batch 8 → 64 moved vector rate by 7%, not 8×, because the model saturates on tokens per second. Batch size is not the lever; how much text you choose to embed is. **Decision: index title+lede first** (~2.7 h after dedupe) and let R.4's ablation decide whether chunking earns its 20 h, rather than spending the 20 h to avoid asking. Payload carries `symbol`/`date`/`event_type` so retrieval filters by entity and time window — **a dated corpus retrieved without a date filter is the M.7 look-ahead mistake in a different costume**. One detail that fails silently: `nomic-embed-text` is asymmetric and needs `search_document:` / `search_query:` prefixes — omit them and vectors still return, dimensions still match, nothing errors, retrieval is just quietly worse. *Remaining: the embedding pipeline itself, plus incremental daily indexing — a pipeline needing a full reindex to stay current is not a pipeline*
- [ ] **R.2** Hybrid retrieval — fuse the existing MongoDB weighted text indexes (sparse, exact-term, strong on tickers) with dense retrieval via reciprocal-rank fusion. `$text` finds "Micron DRAM oversupply" and misses "memory glut pressures chip makers"; dense does the reverse. The failure modes are complementary, which is the whole argument for hybrid — and this corpus can demonstrate both halves on real queries instead of describing them. The sparse leg already exists, built for I.6
- [ ] **R.3** Cross-encoder reranking — retrieve top-100 by fusion, rerank to top-10. Bi-encoder similarity is computed without query and document ever meeting; a cross-encoder scores the pair jointly, is far better at relevance, and is far too slow over 845K rows. Retrieve-then-rerank is how that tradeoff resolves, with the latency budget as the design constraint
- [ ] **R.4** Retrieval evaluation harness — `recall@k`, `MRR`, `nDCG@10` on 50–100 labelled queries drawn from real events already in the corpus, reported as an ablation across sparse / dense / hybrid / hybrid+rerank. **This is the item that actually answers "expected more technical depth"**: a table showing hybrid+rerank at `recall@10 = 0.87` against dense-only at `0.61`, plus which queries the reranker fixed and which it broke. A longer list of implemented components answers nothing. F.22's evaluation harness already set this pattern in the codebase; this points the same discipline at retrieval
- [ ] **R.5** MCP server in Java — a second MCP endpoint inside `quant_api` (Spring Boot 3 / Java 21, Spring AI MCP support) over **streamable HTTP** rather than stdio, authenticated through the Keycloak realm already running in this stack. The highest-value single item here: it is the only one that makes "Java backend engineer" and "AI at scale" the same sentence instead of two claims about two services. It also fixes a real hole — personal holdings are currently exposed over MCP with no auth at all, which is fine for a local stdio process and indefensible over HTTP
- [ ] **R.6** MCP protocol depth — resources with URIs and subscriptions (the tool-vs-resource split is a genuine design call worth having made on real data), server-side versioned prompts, **sampling** so the server can ask the client's model to summarise retrieved news and needs no model credentials of its own, and elicitation + progress + cancellation, which become mandatory the moment a tool writes (I.3 order execution) or runs long. Confirmation belongs in the protocol, not the prompt
- [ ] **R.7** RAG as a feature source, not a chat feature — retrieval-grounded event extraction writing into the feature store. This is where the N-series meets the R-series: semantic retrieval over 845K articles is exactly the mechanism that surfaces "ChangXin Memory IPO" as relevant to MU/WDC/STX when no article names them. Every grounded claim carries its source article ids, and retrieval stays dated, since this is the code path where a retrieval bug becomes a look-ahead bug
- [ ] **R.8** Scale concerns — content-hash embedding cache for idempotent re-runs, index versioning and zero-downtime reindex when the embedding model changes, measured p50/p99 broken down across embed / retrieve / rerank / generate, cost per query local versus hosted, and a labelled degradation path when Qdrant is unreachable — the same honesty as `QuoteService` labelling a daily close served in place of a live quote
- [ ] **R.9** Answerability checklist — not a build item. If any question in it still needs hedging once R.1–R.8 ship, the work is not done. "Scale" carries nothing without document count, throughput, latency, and cost attached

### AI Engineering — LLM / RAG
- [ ] **F.2** News semantic search UI — a search box in quant_ui over the R.2 retriever. Superseded on the retrieval side by R.1–R.3; the entry previously claimed "Qdrant already deployed", which was never true — there is no `qdrant` service in `docker-compose.yml`
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
- [x] **F.17** Portfolio Manager agent — a **review layer over the rule engine**, not a replacement. `track_positions.py` already decides entries, exits and stops deterministically; a local 9B model would be both worse and non-reproducible at that job, and "why do you think the model beats your rules" has no good answer. The agent reviews those decisions instead, covering the two things a per-position rule structurally cannot do: reading *why* a price moved (it pulls the news via I.6 and the feature trend via I.7, so a stop fired by a sector-wide selloff that has already reversed reads as a whipsaw rather than a signal), and portfolio-level facts no rule considers. **The division of labour is the design**: code gathers context, picks what to review, fetches evidence, and runs every portfolio check — concentration and weight limits are arithmetic, and asking a model to do arithmetic a comparison operator cannot get wrong is a bad trade; the model handles only what needs language. Three gates then run on every verdict, trusting nothing: **schema** (one repair round-trip, then the review is dropped rather than emitted malformed), **grounding** (every cited `(tool, field, value)` must appear in a real observation from this run — numbers match with tolerance, since a model echoing 0.2803 as 0.28 is quoting rather than fabricating; a `flag` resting on nothing verifiable is demoted to `agree`), and **business rules**. Output is a machine-consumable decision table, so G.1 can later execute against it. First real run reviewed two rule exits in 213s on a local 9B: one AGREE at 0.9 confidence with three grounded citations, one SKIPPED when the model dropped its connection — degrading rather than crashing, which is what the gates are for. It also surfaced three portfolio findings the rule engine cannot see, including a single position at 41.9% of capital against a 5% limit. 25 unit tests with the LLM and MCP mocked.
- [x] **F.22** Agent evaluation harness — `eval/cases.yaml` plus `eval/run_eval.py`. Whether a recommendation *makes money* cannot be scored without waiting for the market, and claiming otherwise would be dishonest; what is scored are the failure modes that actually keep agents out of production: schema validity, **grounding rate** (fraction of cited evidence that is real), tool recall and precision against the tools each case requires or forbids, run-to-run stability as mean pairwise Jaccard over repeated identical runs, and cost in steps and seconds. Stability earns its place — an agent that answers differently every time cannot be trusted even when each answer is defensible, and a demo run once cannot reveal it. The unit tests mock the LLM, so they prove the loop is correct rather than that the decisions are; this drives the real model against fixed cases to close that gap. One case asks about a symbol the corpus genuinely has no data for, so a run that reports the absence passes and one that produces a confident number fails.

- [ ] **F.18** Backtest reflection agent — auto-diagnose weak-year IC failures (2022/2024) and generate a hypothesis report
- [ ] **F.20** Dip-buy scanner agent — negative-news burst / earnings miss / drawdown on the watchlist → triage sentiment washout vs falling knife → contrarian entry candidates with reasoning

### MCP Integration

Breadth is shipped — ten tools, three independent clients, one tool contract. Depth is not: `stdio` is the only transport, every tool is read-only, there is no auth, and no part of the protocol beyond `@mcp.tool()` is touched. That is tracked as **R.5** (Java server, streamable HTTP, Keycloak OAuth) and **R.6** (resources, prompts, sampling, elicitation).

- [x] **I.1** MCP server (`quant_ai/mcp_server.py`) — eight read-only MCP tools (news sentiment, features, ranked signals, rule-generated positions, the user's own holdings and trade log, backtest performance, universe) over stdio, served through the `quant_api` layer
- [x] **I.2** Claude Desktop integration — registered in `claude_desktop_config.json`, verified end-to-end over the real MCP protocol
- [ ] **I.3** Alpaca order execution via MCP — order tools behind server-side pre-trade guardrails, so agents trade through the same interface
- [ ] **I.4** External data MCP tools — Finnhub / SEC EDGAR / yfinance wrapped as MCP tools so agents decide what to fetch
- [x] **I.6** `search_news` — full-text search over the 845K labeled articles, filterable by symbol and date, returning headline, date, a 400-char excerpt, merged sentiment, model disagreement, event type and URL. Every other tool returns a pre-computed aggregate, so a client could learn a symbol averaged +0.31 sentiment but could not read one article behind it; this turns the server from something that reports conclusions into something that can be interrogated. Weighted text index (title 10x over body) so a headline match outranks a passing mention — the same "incidental mention" distinction the labeling pipeline cares about. **Two indexes were missing entirely**: the collection had only `_id`, so every symbol query was a COLLSCAN over 851K documents (3,011ms to return 2,744 rows); a `{symbol:1, date:-1}` compound index took it to 26ms. The 2.1GB text index also forced the WiredTiger cache from 1GB to 4GB — below that it could not be held in memory and searches ran 0.2–6s warm or cold. Now 67ms for a specific term, ~1.8s for a broad multi-word one (`$text` is OR semantics, so "data center demand" scores 277K matches). Surfaced a data bug too: `date` is stored as both YYYYMMDD (588K) and YYYYMMDDHHMMSS (263K), so a lexical upper bound silently dropped same-day timestamped articles.
- [x] **I.7** `get_feature_history` — feature time series for a symbol, plus a per-field summary (first, last, change, min, max, mean) so a caller reads the direction without walking every row. `get_stock_features` returns only the latest row, so "is sentiment improving or deteriorating" was unanswerable — and +0.29 means something very different when it rose from +0.09 than when it fell from +0.60. A row carries 123 columns, so `fields` is required, capped at 12, over at most 365 days. **The substance is what it refuses**: `future_ret_5d`–`future_ret_60d` are the training labels, populated on 189,668 of 190,828 rows, and serving them to a research agent is look-ahead leakage — asked about a past date it would read that date's actual future. They are now rejected by name with an explanation rather than silently dropped. The existing latest-row endpoint was safe only by accident (it keeps the first 25 fields in document order and `future_ret_*` sorts after them); it filters by name now too. Fixed alongside: the MCP server treated every non-200 as "service unavailable", so a 400 explaining a refused field became "is the container running?" — 4xx bodies now reach the model, 5xx and connection failures still trigger the mongo fallback.
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

### News Propagation — events outside the universe (N-series)

The pipeline matches an article to a company by name, so an event only registers when the
article names a covered symbol. When ChangXin Memory listed and rose 471%, US memory names
moved — but no article about ChangXin mentions Micron, so the platform saw nothing. The
corpus is not the limitation: ChangXin appears in 173 articles, 53 of them in 2026. The
missing piece is propagation, and the honest question is not "can this be captured" but
"does capturing it predict anything".

- [x] **N.0** Intraday collector schema repair — *prerequisite, done*. The finnhub /
  newsapi / yahoo collectors wrote documents with neither `date` nor `symbol`, and
  `slm_company_match_v2.build_query()` requires a symbol, so **every article they collected
  from 2026-04-13 onward stopped dead in `news_articles`**: never matched, never labeled,
  never featurised, never in a signal. 9,636 articles accumulated that way — the freshest
  news in the platform was the only news nothing downstream could see, which is precisely
  why same-day alerting was impossible. A shared `collectors/news/_canonical.py` now
  derives `date` from `publishedAt` and assigns a *candidate* symbol from the 100 company
  rule files; the SLM validator downstream still decides whether the match is real.
  Matching is deliberately conservative — AAPL's primary keyword is `Apple Inc.`, not bare
  `Apple` — because a wrong symbol pollutes that ticker's sentiment aggregate while a
  missing one merely omits an article, and the validator can reject a bad candidate but
  never sees an article that has none. Backfill: 41% of the stranded articles match a
  covered company; the remaining 5,688 are general and macro news, kept unmatched on
  purpose since they are exactly the raw material N.1–N.3 need.
- [ ] **N.1** Influencer entity registry — a second dictionary alongside `company_rules`,
  for entities that are *not* in the universe but move it: foundries and memory makers
  (ChangXin, TSMC, Samsung, SK Hynix, ASML), macro actors (OPEC, the Fed, export-control
  announcements), and named conflicts. Each maps to affected symbols **with a direction**,
  because the sign is not derivable from the entity alone — a competitor's successful IPO
  is bearish for incumbents while rising DRAM prices are bullish for the same names.
- [ ] **N.2** Theme labels in the labeling pipeline — the dual-LLM pass already reads every
  article, so a theme tag (memory cycle, AI capex, export controls, energy, conflict) is
  close to zero marginal cost. Themes cover what an entity registry cannot enumerate in
  advance; the registry covers what a theme is too coarse to catch.
- [ ] **N.3** Theme → symbol exposure matrix — which of the 100 are exposed to "DRAM
  oversupply", and how strongly. Seeded from the `sector` field already in the feature
  store, extended by LLM proposal under human review, and expressed as an exposure weight
  rather than a boolean.
- [ ] **N.4** **Event-study validation — the point of the whole series.** When a theme or
  influencer event fires, what is the distribution of *excess* returns (already
  benchmark-adjusted via `excess_ret_*`) for exposed symbols over 1/5/20 days? Reporting
  absolute returns here would be worthless: memory stocks falling on a day the whole market
  fell proves nothing. Two failure modes get measured explicitly — **hindsight bias**, by
  fixing the event list before looking at returns rather than starting from a move and
  hunting for its cause, and **statistical power**, by reporting how many independent
  events a theme actually has. A theme that fires five times a year cannot support a
  factor, whatever the point estimate says.
- [ ] **N.5** Holdings alerting on validated themes — extends F.16 from symbol-scoped to
  theme-scoped, and **only for themes N.4 found predictive**. Themes that explain without
  predicting stay available as a research tool: telling the user why a position moved today
  is genuinely useful, and is a different claim from telling them what to buy tomorrow.
  Keeping those two apart is the discipline this series is built around.

### Stock Universe
- [x] Universe at 100 US symbols — STX / WDC / HXSCL were added to the watchlist but carry no usable news or features, so they are excluded from the reported universe
- [ ] **G.2** Phase 2–4 expansion — energy/materials (XOM, CVX, NEE, LIN, APD), international ADRs (BABA, JD, PDD, SE), then REITs/financials
