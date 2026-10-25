# Quant Data Project Plan

## Goal
Build a research-ready, then production-ready, mid-frequency stock prediction system for holding periods of:

- 1 week
- 2-4 weeks
- 2-3 months

The immediate objective is not live trading. The immediate objective is:

- reliable data pipelines
- clean research datasets
- factor validation
- backtesting
- model-ready feature tables

## Current Status

What already exists:

- historical and incremental news collection
- stock daily price collection
- company-match cleaning pipeline for news
- cleaned matched-news collection:
  - `news_articles_company_matched_v1`
- daily feature build pipeline
- cleaned feature collection:
  - `daily_symbol_features_company_matched_v1`
- first-pass single-factor backtest script

What is still missing:

- benchmark-relative labels and evaluation
- stronger research-quality filtering layer
- richer factor library
- grouped / long-short backtests
- model training pipeline
- portfolio construction layer
- production signal generation layer

## System Scope

The system should support:

- company/news relevance filtering
- daily feature generation
- mid-horizon return prediction
- factor and model research
- portfolio simulation
- scheduled data refresh
- production deployment later

## Required Data

### 1. News Data
Already partially done.

Needed:

- raw news store
- company-matched clean news store
- source metadata
- title
- body/content
- data quality tags
- company relevance result

Current collections:

- `news_articles`
- `news_articles_company_matched_v1`

### 2. Price Data
Needed:

- daily OHLCV
- adjusted close if possible
- volume
- trading date alignment

Current collection:

- `stock_prices_history`

### 3. Benchmark and Market Data
Still needed / should be added:

- SPY / QQQ / sector ETF daily prices
- benchmark forward returns
- optional factor benchmarks:
  - momentum
  - size
  - quality
  - volatility

### 4. Fundamental / Event Data
Recommended next:

- earnings dates
- EPS / revenue / guidance
- valuation metrics
- analyst estimate revision data if available
- corporate actions

### 5. Metadata
Needed:

- sector / industry
- market cap bucket
- symbol universe definition
- active/inactive date ranges

## Core Collections / Tables

### Raw Layer

- `news_articles`
- `stock_prices_history`

### Clean Layer

- `news_articles_company_matched_v1`

### Feature Layer

- `daily_symbol_features_company_matched_v1`

### Planned Next Collections

- `daily_symbol_features_research_v1`
  - optional refined feature table after additional research-quality filtering
- `backtest_results`
  - optional persistent experiment tracking
- `benchmark_prices`
  - benchmark ETF / index data
- `earnings_events`
  - earnings calendar / event layer

## Current Feature Set

Already generated in daily features:

- `article_count`
- `full_count`
- `title_only_count`
- `url_only_count`
- `full_ratio`
- `title_only_ratio`
- `avg_content_length`
- `max_content_length`
- `unique_url_count`
- `unique_source_count`
- `unique_platform_count`
- `extraction_failed_count`
- `timeout_fallback_count`
- `news_count_3d`
- `news_count_5d`
- `news_count_20d`
- `full_count_5d`
- `avg_full_ratio_5d`
- `news_burst_20d`
- `trade_date`
- `close`
- `future_ret_5d`
- `future_ret_20d`
- `future_ret_60d`

## Prediction Targets

The system should support multiple target definitions.

### Absolute Return Targets

- `future_ret_5d`
- `future_ret_20d`
- `future_ret_60d`

### Direction Targets

- `future_ret_5d > 0`
- `future_ret_20d > 0`
- `future_ret_60d > 0`

### Recommended Future Targets

- benchmark-relative return:
  - stock return minus SPY / QQQ / sector ETF return
- ranking target:
  - cross-sectional rank by future return

For this project, ranking and excess-return targets are likely more useful than pure up/down classification.

## Research Workflow

### Phase 1. Data Integrity

Done or mostly done:

- collect raw news
- clean company relevance
- build daily features
- align with price labels

Still needed:

- benchmark alignment
- event/fundamental enrichment

### Phase 2. Factor Research

Current next step.

Need to run:

- top/bottom bucket tests
- long-short tests
- top 3 / top 5 / top 10 portfolio comparisons
- stability by year
- stability by horizon

First candidate factors:

- `full_ratio`
- `news_burst_20d`
- `article_count`
- `unique_source_count`
- `avg_content_length`
- `extraction_failed_count` as a reverse-quality feature

### Phase 3. Multi-Factor Research

After single-factor validation:

- combine quality factors
- combine quantity + quality + recency factors
- compare weighted score vs single-factor selection

### Phase 4. Modeling

Only after factor validation.

Recommended order:

1. linear / logistic models
2. tree models:
   - LightGBM
   - XGBoost
3. ranking models

Do not start with large text models for price prediction.

### Phase 5. Portfolio Construction

Need explicit rules for:

- rebalance frequency
- top N holdings
- equal weight vs score weight
- sector cap
- single-name cap
- turnover limit
- transaction cost assumptions

### Phase 6. Production

Later phase:

- daily incremental collection
- feature refresh
- model scoring
- signal generation
- order routing
- monitoring
- logging
- retry / failure handling

## Research Principles

### 1. Prefer simple baselines first

Always test:

- single factor
- grouped returns
- naive top-N strategy

before training larger models.

### 2. Use safe date windows

Backtests should use:

- `trade_date >= 2015-12-04`

because current price data coverage starts there.

### 3. Use clean collection by default

Research should prefer:

- `news_articles_company_matched_v1`
- `daily_symbol_features_company_matched_v1`

instead of raw collections.

### 4. Keep raw data immutable

Do not delete raw source collections.

Use separate clean / derived layers.

## Engineering Plan

## Stage 1. Immediate Next Tasks

1. Extend first-pass backtest
- top / bottom buckets
- long-short
- top 3 / top 5 / top 10

2. Add benchmark comparison
- SPY / QQQ / sector baseline

3. Build quality factor basket
- combine `full_ratio`, `unique_source_count`, `avg_content_length`, etc.

4. Validate by horizon
- 5d
- 20d
- 60d

## Stage 2. Near-Term Data Expansion

Status: substantially complete.

### Completed items

- benchmark/index price collection:
  - done (`SPY`, `QQQ` daily prices, `benchmark_ret_5d/20d/60d`, `excess_ret_*`)
- earnings event Layer 1 (timing only):
  - done
  - features: `days_to_earnings`, `days_since_earnings`,
    `is_earnings_window_5d`, `is_post_earnings_window_20d`
- earnings event Layer 2 (surprise + richer timing):
  - done
  - features: `eps_estimate_last`, `reported_eps_last`, `surprise_pct_last`,
    `is_positive_surprise`, `is_negative_surprise`,
    `days_to_earnings_bucket`, `days_since_earnings_bucket`,
    `is_pre_earnings_10d`, `is_post_earnings_5d`, `is_post_earnings_10d`,
    `is_post_positive_surprise_20d`, `is_post_negative_surprise_20d`
  - result: Ridge `60d` IC improved from `0.073` to `0.121` (+66%)
- sector mapping: basic version integrated

### Next: earnings event Layer 3

Build on Layer 2 with deeper surprise structure and interaction features.

1. surprise magnitude buckets
   - split `surprise_pct_last` into ordinal buckets:
     - large miss (< -5%), small miss (-5% to 0), small beat (0 to +5%),
       large beat (> +5%)
   - rationale: the market reacts non-linearly to surprise size

2. news quality × earnings interaction features
   - `full_ratio_x_post_positive`: `full_ratio` × `is_post_positive_surprise_20d`
   - `quality_score_x_post_negative`: `quality_score` × `is_post_negative_surprise_20d`
   - rationale: a positive surprise with high-quality news coverage is a
     stronger combined signal than either alone

3. earnings recency decay
   - `earnings_recency_weight`: exponential decay of `days_since_earnings`
     (weight = exp(-days_since / 20))
   - rationale: the post-earnings drift effect weakens as time passes

4. rerun backtest and model after Layer 3
   - compare against the Layer 2 baseline (Ridge `60d` IC = `0.121`)

### Most important next step: universe expansion

The current universe is 14 symbols.
This is the single biggest constraint on signal reliability.

Why this matters:

- at 14 symbols, one bad year (e.g. 2022, 2024) can make the IC negative
  due to sampling noise alone
- cross-sectional ranking needs depth: `top 3 / top 5` out of 14 is not
  robust; `top 5 / top 10` out of 50-100 is meaningfully more stable
- the current signals may be real but cannot be confirmed at this universe size

Target: expand to 50-100 symbols.

What is required:

1. extend `stock_universe` collection with new symbols
   - suggested scope: S&P 500 tech/growth names, or a defined sector basket
   - keep sector distribution balanced

2. collect historical news for new symbols
   - extend GDELT / news collector coverage
   - run `company_match_rescore` on new articles

3. collect price history for new symbols
   - extend `stock_prices_history`

4. rebuild feature table
   - `FEATURE_REBUILD_ALL=true` after data is ready

5. rerun all backtests and models on expanded universe
   - compare single-factor IC at 50-symbol vs 14-symbol universe
   - a good signal should survive and become more stable

## Stage 3. Modeling

Status: first-pass baselines done.

Current baseline results (14-symbol universe):

- `Ridge` `60d` Rank IC: `0.121` / Top 5 excess return: `+6.58%`
- `HistGB` `60d` Rank IC: `0.118` / Top 5 excess return: `+6.32%`

Known issue: year-by-year variance is high.

- strong years: 2020 (IC = 0.35), 2023 (IC = 0.19), 2025 (IC = 0.24)
- weak years: 2022 (IC = -0.06), 2024 (IC = -0.04)
- likely cause: macro regime shifts (2022: rate hikes + war; 2024: election
  + rate pivot) break the news-quality thesis temporarily

Next modeling steps (do only after universe expansion):

1. year stability analysis
   - run `--group-by-year` on factor backtest with full feature set
   - identify which features drive the 2022/2024 failures
   - test whether regime-aware features (e.g. VIX level, market vol) help

2. simple Ridge + HistGB ensemble
   - average predictions from both models
   - rationale: the two models now have comparable IC and different error
     patterns; blending should reduce variance

3. sector-relative feature normalization
   - normalize `full_ratio`, `quality_score` within sector on each day
   - reduces bias from sectors that structurally attract more/less news

4. ranking model
   - convert to a pairwise ranking objective (LambdaRank or similar)
   - more directly aligned with the top-N portfolio construction goal

## Stage 3.5 Event-Driven Strategy Research

Goal: evolve the fixed-horizon model into a news event-driven strategy where
signals trigger dynamic entry, hold, and exit decisions rather than fixed
holding periods.

This stage must be completed before Stage 5 engineering work begins.

### 3.5.1 Article-level event tagging (LLM batch annotation) ✅ Done 2026-05-22

All 840,212 articles in `news_articles_company_matched_v2` tagged with:

- Pass A (Gemma): `llm_sentiment_a`, `llm_event_type_a`, `llm_signal_strength_a` — 100%
- Pass B (Qwen): `llm_sentiment_b`, `llm_event_type_b`, `llm_signal_strength_b` — 100%
- Dual-LLM merge: `llm_sentiment_final`, `llm_disagreement`, `llm_label_model_probs` — 100%
- Inter-model agreement rate 77.3%; mean sentiment +0.296 (overall positive bias)

Deliverable: `research/labeling/llm_enrich_articles.py`, `research/snorkel_label_merge.py`

Resume framing:
*"Enriched 845K financial news articles with two-pass LLM ensemble (Gemma +
Qwen), merged by a hand-written dual-LLM reconciler achieving 77.3% inter-model
agreement on sentiment, event type, and signal strength labels."*

### 3.5.2 Event-level daily features ✅ Done 2026-05-22

Rebuilt `daily_symbol_features_company_matched_v2` (134,642 rows, 100 symbols)
with full LLM sentiment feature coverage (100%):

| Feature | Coverage |
|---|---|
| `avg_sentiment_3d/5d` | 100% |
| `sentiment_shift_5d` | 99.6% |
| `high_signal_count_3d` | 100% |
| `negative_event_count_5d` | 100% |
| `disagreement_avg_5d` | 100% |
| `has_regulatory_risk_5d` | 100% |
| `earnings_beat_signal` / `earnings_miss_signal` | 100% |

Multi-horizon model results with LLM features (walk-forward, 100 symbols):

| Horizon | Ridge IC | Ensemble IC | Ensemble Top5 Excess Return |
|---|---|---|---|
| 20d | 0.036 | 0.031 | +1.83% |
| 45d | 0.044 | 0.043 | +4.38% |
| 60d | 0.056 | 0.059 | +6.59% |

IC increases monotonically with holding period; the 60d signal is strongest.

Deliverable: `research/features/daily_symbol_features.py`, `research/models/train_baseline_models.py`

### 3.5.3 Dynamic holding period backtest ✅ Done 2026-05-22

Event-driven framework results (100 symbols, 2018–2026):

Best config: `min_hold=20d`, `max_hold=60d`, `sentiment_shift_exit=-0.35`

| Metric | Event-Driven | Fixed 20d Baseline | Fixed 60d Baseline |
|---|---|---|---|
| Avg Hold | 13.7d | 20d | 60d |
| Excess Return | +1.40% | +1.22% | +3.80% |
| Win Rate | 52.7% | 58.0% | 63.1% |
| Trades | 390 | 2,060 | 2,020 |

Event-driven outperforms the fixed 20d baseline within 13.7 days (+1.40% vs +1.22%) with lower turnover.
Exit reasons: score_below_exit 69%, sentiment_reversal 17% (reasonable).
2022/2024 remain weak years (macroeconomic regime shifts).

Deliverable: `research/backtest/backtest_event_driven.py`

### 3.5.4 Multi-horizon label expansion ✅ Done 2026-05-22

Added to `daily_symbol_features_company_matched_v2`:
- `future_ret_10d/15d/30d/45d` — 87-88% coverage
- `excess_ret_10d/15d/30d/45d` — 87-88% coverage
- Also fixed `load_feature_frame` projection in `backtest_news_factor.py`

Deliverable: `research/features/daily_symbol_features.py`, `research/backtest/backtest_news_factor.py`

### 3.5.5 Fine-tune small model for sentiment scoring

After the two-pass LLM enrichment (3.5.1) completes, replace the slow LLM
inference pipeline with a purpose-fine-tuned small model. This eliminates the
need to keep Gemma + Qwen + a judge model running and reduces inference from
days to minutes.

**Training data**

Use articles where Pass A (Gemma) and Pass B (Qwen) agree as high-confidence
pseudo-labels:
- `llm_sentiment_a` and `llm_sentiment_b` same sign AND |diff| ≤ 0.2
- Expected: ~60-70% of 586K articles → ~350K+ clean training samples

**Model**

Fine-tune `ProsusAI/finbert` (110M params, already pre-trained on financial
text) with three output heads:
- sentiment: regression head, output -1.0 to +1.0
- event_type: 7-class softmax (earnings / product / MA / regulation / macro /
  competition / other)
- signal_strength: 3-class softmax (high / medium / low)

Training setup:
- LoRA or full fine-tune (BERT is small enough for full fine-tune)
- GPU: Windows machine (same as LM Studio)
- Estimated training time: 1-2 hours on 350K samples
- Framework: HuggingFace Transformers + PyTorch

**Inference speed after fine-tuning**

| Setup | Speed |
|---|---|
| Current LLM (Gemma via LM Studio) | ~3.9 art/s |
| Fine-tuned FinBERT (GPU) | ~1000-2000 art/s |
| Fine-tuned FinBERT (CPU only) | ~200 art/s |

586K articles: current ~41h → fine-tuned ~5-10 min

**Deliverables**

- `research/finetune_sentiment.py` — training script
- `research/infer_sentiment.py` — batch inference on remaining articles
- benchmark report: fine-tuned vs LLM scores on held-out set

**Resume framing**

*"Fine-tuned FinBERT on 350K+ pseudo-labeled financial news articles
(distilled from Gemma + Qwen ensemble), achieving 200x inference speedup
while maintaining comparable sentiment, event classification, and signal
strength accuracy."*

### Execution order

1. 3.5.4 Multi-horizon labels ✅
2. 3.5.1 Article tagging ✅
3. 3.5.2 Event features ✅
4. 3.5.3 Dynamic backtest ✅
5. 3.5.5 Fine-tune small model — Pending development

---

## Stage 4. Production Readiness

1. schedule feature build from clean news
2. track model versions
3. persist experiment results
4. build daily signal job
5. add monitoring

## File / Module Roadmap

### Existing

- `research/features/daily_symbol_features.py`
- `research/company_match_rescore.py`
- `research/backtest/backtest_news_factor.py`
- `research/features/load_earnings_events.py`
- `research/load_benchmark_prices.py`
- `research/models/train_baseline_models.py`
- `collectors/news/gdelt/special_rules/slm_filter.py`
- `collectors/news/gdelt/special_rules/slm_skills.py`

### Suggested Next Files

- `research/backtest_year_stability.py`
  - year-by-year IC breakdown with the full feature set
- `research/build_interaction_features.py`
  - earnings × news quality interaction features (Layer 3)
- `research/expand_universe.py`
  - helper to onboard new symbols into stock_universe and trigger collection

## Recommended Success Criteria

The project should be considered healthy if:

- clean company-matched news can be built reproducibly
- feature table refresh is stable
- at least one factor shows persistent positive excess return
- results are stable across multiple years
- simple baselines are competitive before modeling

## Current Practical Recommendation

Do next (in priority order, updated 2026-06-20):

1. **H.1 Backtest with transaction costs + liquidity filter** (2 days) — current Sharpe 0.70-0.84 is pre-cost; quantitative interviews always ask this, highest ROI
2. ~~**Stage 7 validation**~~ ✅ **Done** — Airflow now runs the full DAG set from a host `launchd` scheduler (containers cannot reach the host LLM under VPN), and the Kafka producer/consumer path was verified end to end after fixing a deserializer mismatch that had the consumer stuck in a poison-pill retry loop. Signals publish and are consumed with zero lag.
3. **E.7 README + architecture diagram** (1 day) — required for all interviews, currently missing, fastest result
4. **H.2.2 Dynamic factor weights** (regime-aware) — regime_mult base multiplier already exists; needs extension to auto-switch factor weight sets in volatile market
5. **H.3.2/H.3.3 Paper trading improvements** — position tracking and exit triggers already exist; missing OOS IC monitoring and -5% stop-loss rule
6. **Stage 3.5.5 FinBERT fine-tuning** — train on Gemma+Qwen consensus labels to replace LLM inference pipeline

Completed:

- universe expansion to 100 symbols ✅
- year stability analysis ✅
- earnings Layer 1 / 2 / 3 ✅
- Ridge + LightGBM + Ensemble baseline (60d IC = 0.10, Top5 = +6.7%) ✅
- Stage 3.5.1 LLM article tagging (845K articles, Gemma + Qwen + dual-LLM merge) ✅
- Stage 3.5.2 event-level daily features (134K rows, 100% LLM coverage) ✅
- Stage 3.5.3 event-driven backtest (min20d, +1.40% vs fixed 20d +1.22%) ✅
- Stage 3.5.4 multi-horizon labels (10/15/30/45/60d) ✅
- **D.1/D.2/D.4/D.7/D.8 research layer extensions all completed** (2026-06-16), D.3/D.5/D.6 skipped ✅
- **C.1-C.7, C.9 all completed (baseline versions)** (daily signal automation + UI + position tracking + exit alerts + risk metrics + data quality checks + factor analysis report, 2026-06-16~20) ✅
- **H.2.1 regime multiplier baseline** (score_daily_signals.py integrated macro_risk_on / macro_vix_pctile_252d to adjust signal strength) ✅
- Ops: removed duplicate launchd scheduler job to prevent all collection tasks from running twice daily ✅

Do not do next:

- live trading automation (live trading is still H.1-H.5 fully complete + 3-6 months of paper trading away from being truly usable)
- Stage 5 engineering before Stage 7 validation is complete

## Notes

The clean matched-news dataset is research-usable at the current scale.

The two-layer earnings feature set has produced a meaningful model
improvement (Ridge `60d` IC: `0.073` → `0.121`).

Signal IC at 60d = 0.059 on the 100-symbol universe is more credible than the 0.121 at 14 symbols (a larger universe dilutes overfitting). The weak 2022/2024 years are driven by macroeconomic regime shifts; the signal itself is credible.

---

# Roadmap Overview

Every item carries a stable ID; its detailed spec and effort estimate are in the
lettered sections of this document. Checked items are shipped and running.

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
- 🟡 **M.12** News syndication inflates the volume features — **found while deduplicating the corpus for R.1**, when the 121,970 rows dropped at index time turned out not to be noise. GDELT ingests every site of a syndication network as a separate article: one McDonald's story on 2025-11-03 appears **402 times**, byte-identical body, identical sentiment, 402 distinct `*.iheart.com` subdomains. That symbol-day carries **412 rows and 11 distinct titles**. `unique_url_count` exists to catch this and structurally cannot — 402 subdomains are 402 distinct URLs — and `unique_source_count` falls back to the platform name, mean 1.0139. Both dedupe guards were blind to the dominant duplication mode. Measured by running the *production* aggregators twice, once raw and once deduplicated on `(symbol, date, title)`: `news_articles` is **14.6%** duplicate and `news_articles_company_matched_v2` **14.3%**; `news_burst_20d` differs on **93.6% of symbol-days** and `news_count_20d` on 93.2%, while `sent_wavg` barely moves in aggregate (0.3221 → 0.3224, 15.1% of rows) because a syndicated copy usually carries a sentiment near the day's mean. **The damage is in the volume features, not sentiment.** The reason it distorts a cross-sectional rank rather than shifting a level: per-symbol duplicate share runs **2.3% to 52.4%**, concentrated in the consumer brands that radio and lifestyle networks syndicate (MCD 52.4, SBUX 38.3, MRNA 37.3, TGT 36.6, BA 36.1, DIS 31.4 against a 16.0 corpus mean) — a uniform inflation would cancel in a rank, this lifts some names by half and others by nothing, correlated with sector. It reaches the signal: `news_burst_20d` carries regime weights **0.9 / 0.8 / 0.5 / 0.2** in `score_daily_signals.py` and sits in the model feature list beside `article_count` and `news_burst_20d_sector_rel` — and the sector-relative variant does not neutralise a bias that is itself sector-correlated. **This is the M.7 shape again**: the hand-weighted regime scorer assigning high weight to an input nobody had validated. **Measured** by building two shadow feature sets from identical code at the same moment, differing only in the dedupe flag (the off build verified a genuine no-op first: 4,000 sampled symbol-days differed from production on **0 rows**). **The ML walk-forward barely notices** — 60d Ensemble rank IC 0.0572 → 0.0549, every cell moving less than 0.005 with inconsistent signs, which without error bars is not distinguishable from noise and is not claimed as an effect. **The regime scorer does**: on `backtest_portfolio.py`, which imports `compute_score` and `_WEIGHTS_BY_REGIME` directly and is therefore the live signal path, net Sharpe falls **0.654 → 0.580** and net annualised 19.64% → 16.76%, while max drawdown *improves* (−42.08% → −39.56%) and win rate *improves* (63.64% → 65.15%) — a lower-return, lower-risk profile rather than a uniformly worse one. **This is the M.7 pattern repeating exactly**: a tree or a ridge treats `news_burst_20d` as one column among a hundred and learns its weight from data, while the hand-weighted scorer assigned it 0.9 by fiat and lost 0.074 Sharpe when the input was cleaned. Twice now the damage has landed on the hand-calibrated weights rather than the fitted ones — the models at least look at the data before deciding how much to trust a column. The counter-argument worth stating: a story syndicated to 402 stations does have unusual reach, and reach may carry information — but that does not rescue a feature called `article_count` that claims to count distinct news and does not; if reach is the signal it belongs in a named feature that can be tested on its own. Implemented behind `NEWS_DEDUPE_SYNDICATION` in `load_news_frame()` / `load_llm_sentiment_frame()` so every downstream feature inherits it, **default off** until flipping it is a deliberate decision rather than a side effect
- [ ] **M.8** Turnover and capacity reporting — the backtest prices a round trip per position (H.1) but never reports **how many round trips there are**. At a 5-day horizon fed by daily signals, turnover could be high enough that the cost model, though honest per trade, understates the total drag by a wide margin. Report annualised turnover, cost as a share of gross return, and the capital level at which the liquidity filter starts binding — a strategy that works at $50k and not at $5m is a different claim.
- [ ] **M.9** Short-side borrow costs — the long-short Sharpe of 0.85 charges commission and slippage on both legs but nothing for **carrying** the short: no borrow fee, no hard-to-borrow screen, no recall risk. On the names most likely to be shorted by a news-sentiment signal, borrow is exactly where it is expensive. Until this is modelled, the long-short number is optimistic by an unmeasured amount and the long-only figures are the more defensible ones to quote.

### Portfolio & Live Trading
- [x] **P.1** Manual holdings tracker — the only positions the platform knew about were synthetic: `track_positions.py` mechanically opens the day's top-5 signals, so there was nowhere to record what is actually held. **Transactions are the source of truth and holdings are derived** — storing a holding row with an `avgCost` field makes it unmaintainable, because editing the quantity leaves no way to recompute what the average should now be. `portfolio_transactions` (symbol, side, quantity, price, tradeDate, fee, note) with full CRUD so any mis-keyed trade can be corrected, plus a freely editable `portfolio_cash` balance; quantity, running weighted-average cost, unrealised and realised P&L, and weight as a share of *total* capital are folded from the log on read. Live quotes from Finnhub behind a 20s TTL cache (60 req/min free tier cannot survive a page polling 20 symbols), stretched off-hours, falling back to the last `stock_prices_history` close and labelling it as such rather than passing a stale number off as live. **Under the VPN the containerised quant_api has no outbound internet at all** — the same constraint that forces quant_ai to run as a host process — so the deployed page serves daily closes and says so; live quotes work when quant_api runs on the host. Fetching quotes from the host Airflow scheduler into mongo would fix this properly (see G.4). Surfaces: `/api/portfolio/*` on quant_api, a "My Holdings" tab in quant_ui, and `get_my_holdings` / `get_my_transactions` MCP tools — which makes the portfolio readable by Claude Desktop, Codex, and quant_ai's agent at once. 10 unit tests cover the money maths on a pure `replay()` fold (average cost after mixed buys, realised P&L against the average *at the time of sale*, full exit and re-entry, capped overselling). Prerequisite for F.17 and G.1 — neither position sizing nor a 5%-per-position guardrail means anything measured against a portfolio nobody owns. Holdings are personal financial data: they stay in the local database and never reach a seed file, fixture, or commit.
- [ ] **G.4** Intraday quote collector — a host Airflow task polling Finnhub into an `intraday_quotes` collection every few minutes during US market hours, with quant_api reading mongo instead of calling out. Containers have no outbound internet under the VPN, so P.1's live-quote path only works when quant_api runs on the host; moving the fetch to the host scheduler (which does have internet, and already owns every other collector) makes live prices work in the deployed stack and removes the per-request rate-limit pressure at the same time.
- [ ] **G.1** Broker API integration (Alpaca) — **blocked on M.7 and M.1**: wiring a signal contaminated by look-ahead to a live broker converts a methodology error into a cash loss, and no amount of pre-trade guardrail protects against a factor that was reading the future. Wire daily signals to real order execution; pre-trade guardrails: max 5% per position, daily loss kill-switch, whitelist-only symbols, fill reconciliation against paper positions; Stage 1 paper account → Stage 2 live with small capital

### AI at Scale — RAG & MCP depth (R-series, current focus)

The honest starting position: the retrieval layer is `SimpleVectorStore` in `quant_ai/main.py` — numpy cosine similarity over the four markdown files in `knowledge/`, **382 lines of text**, re-embedded into process memory on every startup, falling back to keyword token overlap when the embedding endpoint is unreachable. No chunking, no reranking, no hybrid retrieval, no retrieval metric ever computed. Meanwhile **845K company-matched news articles sit in MongoDB with zero embeddings**. On the MCP side: ten tools, three clients, but stdio only and nothing past `@mcp.tool()` — no resources, prompts, sampling, elicitation, or auth, and all of it Python. The gap is not the concepts; it is that the rarest asset in a RAG interview — a large dated domain corpus with entity labels — was already collected and left unindexed while the demo ran on four README-sized files.

- [x] **R.1** Qdrant + embedding pipeline over the news corpus — **qdrant deployed** (`v1.18.3`, storage bind-mounted to the external drive rather than the container layer, 2 GB memory cap, log rotation: the 584G and 103G disk-full incidents both came from unbounded container growth, and a vector index would repeat that exactly). Corpus measured on 851,071 documents before writing any pipeline, which corrected both assumptions the plan had been carrying: only **30.2% of articles fit a single 512-token window** (median body 2,956 chars), so full chunking is **2.96M vectors / 9.1 GB / 20.0 h**, not the 2.6 GB estimated; and **17.90% (152,332) have no body at all**, making title-only one document in six rather than an edge case. Also found: **121,970 duplicates (14.3%)** on `(symbol, title, date)`, which would have consumed top-k slots and inflated every recall number R.4 produces. Measured throughput of `nomic-embed-text` (768-dim, local): **title+lede 74.2 vec/s → 3.19 h for the full corpus; 512-token chunks 41.1 vec/s → 20.0 h**. The transferable finding is that throughput is **character-bound, not request-bound** — every configuration held 66–74 Kchar/s, and batch 8 → 64 moved vector rate by 7%, not 8×, because the model saturates on tokens per second. Batch size is not the lever; how much text you choose to embed is. **Decision: index title+lede first** (~2.7 h after dedupe) and let R.4's ablation decide whether chunking earns its 20 h, rather than spending the 20 h to avoid asking. Payload carries `symbol`/`date`/`event_type` so retrieval filters by entity and time window — **a dated corpus retrieved without a date filter is the M.7 look-ahead mistake in a different costume**. One detail that fails silently: `nomic-embed-text` is asymmetric and needs `search_document:` / `search_query:` prefixes — omit them and vectors still return, dimensions still match, nothing errors, retrieval is just quietly worse. *Remaining: the embedding pipeline itself, plus incremental daily indexing — a pipeline needing a full reindex to stay current is not a pipeline*
- [x] **R.2** Hybrid retrieval — `tools/hybrid_search.py` fuses the MongoDB weighted text index (title:10, content:1) with the Qdrant dense index via RRF, **on rank rather than score** because `textScore` is an unbounded tf-idf-ish sum while cosine is bounded [-1,1], so weighted-sum fusion would need a normalisation that is itself a tuned parameter. Three defects surfaced by running it rather than reading about it: **the sparse leg had to be deduplicated to match the dense one** (Qdrant is deduplicated per M.12, Mongo is not — fusing a clean list against one where one story occupies 402 candidate slots compares a retriever against a broken one, not two retrievers); **RRF was double-counting**, because `index_news.py` keyed on the raw `date` so points distinct at index time collapse under the normalised fusion key and each occurrence banked another `1/(K+r)` — the **third** defect traceable to that dual date format, after the null `date_int` and the feature-layer key; and **13,027 redundant points (1.79%)** from the same cause, repaired in place in seconds by `tools/repair_index_dupes.py` rather than by re-embedding, since point ids are UUID5 of the mongo `_id` and the surviving vectors were never wrong — only the set was (729,101 → 716,074, matching the independent mongo aggregate exactly). **The result worth recording: naive RRF at the published default (K=60, depth 100, equal legs) underperforms both single legs on the queries tried.** `1/(60+60) + 1/(60+36) = 0.0187` beats `1/(60+1) = 0.0164`, so two mediocre ranks outrank one excellent one — **RRF scores consensus, and consensus is not relevance**. On "memory glut pressures chip makers" it promotes an article about chip factories and Trump over three sparse hits actually about a memory glut; on the bare ticker "LRCX" both legs rank content-free stub pages consistently, so consensus floats them above the real articles and dense alone wins. `K=5` at depth 30 looks much better on both, and **is deliberately not adopted as the default** — "looks better to me on two queries" is the same error as trusting the published default with the source swapped. `RRF_K`, candidate depth and per-leg weights are parameters for R.4 to sweep
- [ ] **R.3** Cross-encoder reranking — retrieve top-100 by fusion, rerank to top-10. Bi-encoder similarity is computed without query and document ever meeting; a cross-encoder scores the pair jointly, is far better at relevance, and is far too slow over 845K rows. Retrieve-then-rerank is how that tradeoff resolves, with the latency budget as the design constraint
- [ ] **R.4** Retrieval evaluation harness — `recall@k`, `MRR`, `nDCG@10` on 50–100 labelled queries drawn from real events already in the corpus, reported as an ablation across sparse / dense / hybrid / hybrid+rerank. **This is the item that actually answers "expected more technical depth"**: a table showing hybrid+rerank at `recall@10 = 0.87` against dense-only at `0.61`, plus which queries the reranker fixed and which it broke. A longer list of implemented components answers nothing. F.22's evaluation harness already set this pattern in the codebase; this points the same discipline at retrieval
- [ ] **R.5** MCP server in Java — a second MCP endpoint inside `quant_api` (Spring Boot 3 / Java 21) over **streamable HTTP** rather than stdio, authenticated through the Keycloak realm already running in this stack. The only item that makes "Java backend engineer" and "AI at scale" one sentence instead of two claims about two services. **Framing that decides what to build**: adding auth to a *stdio* server is close to a non-question — the server is a child process the client spawned, the security boundary is the OS process, and a token there is a secret to store with no security gained. HTTP is what forces the question. It stopped being theoretical when `submit_judgment` shipped: with 10 read-only tools the worst case was disclosure, and a **write tool makes it unauthorised mutation**. Four problems get conflated under "agent auth" — authentication (routine), authorization (moderate), and two that are actually hard: **delegation**, where an agent needs broader permissions than any user and so returns data the asker was never allowed to see (the confused deputy — nothing is compromised, every component behaved correctly, and it is invisible in testing; the fix is a downscoped on-behalf-of token rather than the agent's own standing credential), and **permission-aware retrieval**, where *retrieve-then-filter* can return 2 results and leaks existence while *filter-then-retrieve* is correct only if the store evaluates the predicate inside the search. **This platform is already half-way there**: Qdrant filtering inside the query is that mechanism, and R.10 showed the cost of getting it wrong when one leg filtered inside the search and the other filtered after (37 results instead of 100, and the wrong 37). A date window and a permission boundary are the same filtering problem. Start from the two hard ones — "I added OAuth" is configuration, "I handled permission downscoping when an agent retrieves on a user's behalf" is design
- [ ] **R.6** MCP protocol depth — resources with URIs and subscriptions (the tool-vs-resource split is a genuine design call worth having made on real data), server-side versioned prompts, **sampling** so the server can ask the client's model to summarise retrieved news and needs no model credentials of its own, and elicitation + progress + cancellation, which become mandatory the moment a tool writes (I.3 order execution) or runs long. Confirmation belongs in the protocol, not the prompt
- [ ] **R.7** RAG as a feature source, not a chat feature — retrieval-grounded event extraction writing into the feature store. This is where the N-series meets the R-series: semantic retrieval over 845K articles is exactly the mechanism that surfaces "ChangXin Memory IPO" as relevant to MU/WDC/STX when no article names them. Every grounded claim carries its source article ids, and retrieval stays dated, since this is the code path where a retrieval bug becomes a look-ahead bug
- [ ] **R.8** Scale concerns — content-hash embedding cache for idempotent re-runs, index versioning and zero-downtime reindex when the embedding model changes, measured p50/p99 broken down across embed / retrieve / rerank / generate, cost per query local versus hosted, and a labelled degradation path when Qdrant is unreachable — the same honesty as `QuoteService` labelling a daily close served in place of a live quote
- [ ] **R.9** Answerability checklist — not a build item. If any question in it still needs hedging once R.1–R.8 ship, the work is not done. "Scale" carries nothing without document count, throughput, latency, and cost attached

- [x] **R.10** Retriever wired into generation — `POST /api/ask/news` answers from the 716K-article corpus with citations by article id, **refuses** when retrieval is empty rather than answering from parametric memory (a RAG system that silently falls back still reads as sourced, so its failure is invisible), and passes `symbol` + date window into **both** legs. Additive, not a replacement: `knowledge/` answers "how does the regime scorer weight factors", the news corpus answers "what happened to NVDA on export controls". Two defects surfaced only by wiring it: **the legs filtered asymmetrically** — qdrant filtered inside the search while the sparse leg took the best matches across all history and filtered in Python after, so one NVDA query returned 37 hits instead of 100 and they were the wrong 37, which **would have corrupted R.4's ablation silently**; and **body fetch took 5.9s** because `find_one({symbol, title})` has no index to use, now 1.5ms via one `$in` on the mongo `_id` both legs carry. Measured latency split rather than totalled — dense leg 16–23ms, sparse `$text` 1.1–3.6s, body fetch 1.5ms, **generation 66–111s**. Generation is 99% of it and the model is not slow: 47 tok/s is normal for a 9B on Apple Silicon, but it emitted **3,124 completion tokens for a ~100-token answer** — a thinking model spending ~3,000 tokens of hidden reasoning on summarisation. Disabling thinking timed out rather than helping, so it is recorded as **open**. Quality note: asked how investors reacted to Micron's guidance, it reported that the excerpts *disagree* (2019-09-25 "positively surprised" vs 2019-09-27 "stock tumbles") and cited both sides instead of picking one
- [x] **R.11** Generation-side evaluation — retrieval metrics say the right document was in the context window, not whether the answer used it. faithfulness/groundedness, citation accuracy (a citation to a real document that does not contain the claim is a hallucination wearing a source), answer relevance. Reuses F.17's grounding gate, pointed at documents instead of tool outputs
- [ ] **R.13** One agent for every stock question — the F.21 agent decides which tools to call (cited news answers, signals, backtest, holdings and quotes, briefs, or none); fix the signals/performance 401, add the quant_ai tools, no thinking on agent steps, and a tool-selection evaluation set
### Security — the AI attack surface
- [x] **S.1** Indirect prompt injection defence — R.10 opened the exposure: `/api/ask/news` retrieves from 716,074 articles scraped from the open web and puts their body text in the model's context, so **nobody has to compromise anything to write there** — publishing an article GDELT ingests is enough. The system prompt telling the model to answer *only* from those excerpts makes an injected instruction **more** persuasive, not less, and R.7 intends to feed retrieval into the feature store, where a poisoned answer becomes a poisoned position. Four layers, deliberately unequal: **structural separation** (retrieved text lives only in a user message inside `<excerpt>` delimiters, with the system prompt stating nothing inside can change the rules — this is the real defence, because it is about *where authority lives* rather than what the text says), **sanitisation** (zero-width, bidi and control characters neutralised, deterministic so rewording cannot evade it), **pattern detection** (7 regexes — the weak layer, reported and never enforced: dropping a document on a regex match would let anyone suppress coverage of a company by publishing one sentence), and **output checks**. Measured rather than assumed: the first exfiltration pattern fired 16 times in 40,000 real articles, every one an earnings-call transcript where the operator asks analysts to "repeat your instructions" — a rule that fires on ordinary journalism is worse than no rule, because the flag then gets ignored on the day it matters. Final false-positive rate **3 in 40,000 (0.0075%)**. **Two defects the tests found rather than review**: deleting zero-width characters *helped* the attacker, since `Ignore<ZWSP>all<ZWSP>previous<ZWSP>instructions` collapses into one unmatchable token while a model reads the phrase fine through the missing spaces — neutralising a hiding character must not destroy the evidence, so they are replaced with a space; and `chars_sanitised` was a length delta, which is always 0 once characters are replaced instead of deleted, so the metric hid the signal it existed to surface. **Three evasion tests assert the pattern layer fails** on rewording, indirect framing and non-English — asserted rather than hidden, because that is the argument for the layering. End-to-end against a local 9B with a poisoned excerpt the model reported the real figure and **called out the embedded instruction** instead of following it; the automated adoption check false-positived on that answer because the model *mentioned* the injected phrasing in order to report it, and a substring test cannot separate adopting from reporting — the same difficulty R.11's faithfulness gate will face. 22 tests
- [x] **S.2** Guard at the MCP boundary rather than in each consumer — S.1 protected one endpoint, while `search_news` was still handing raw article text unguarded to **four** consumers: Claude Desktop, Codex, the F.21 research agent and the F.17 portfolio agent. It is the only tool on that server returning free text written outside the platform (every other returns platform-computed numbers), which makes it *the* injection surface. **The guard goes at the tool boundary, not in each consumer**: four implementations would be four chances to drift and a client registered later would arrive unprotected, whereas the boundary where untrusted text crosses into a model context is exactly the boundary the tool contract already defines — the same argument that let one stdio server serve three clients. Title, excerpt and company are sanitised, pattern hits attach per article as `untrusted_content_flags`, and a `_security` block states the text is data to report on rather than instructions to follow. **Reports, never withholds** — dropping an article on a regex match would let anyone erase a company from the platform's coverage with one sentence — and **fails open, asserted in a test**, because dropping every article when a payload will not parse would be a self-inflicted denial of service while the structural defence still holds. Verified against the redeployed API and over the real MCP protocol; 54 tests across the suite
- [ ] **S.3** Identity that is a principal, not a parameter — `get_eval_batch(judge_id)` and `submit_judgment(judge_id, …)` take the judge's identity as an **argument the caller supplies**. Today that is not a privilege boundary and should not be described as one: `judge_id` is a label namespace (`claude-desktop`, `codex`) whose only job is keeping each judge's labels separable so inter-judge agreement can be measured, and there is no user data behind it. **The cost lands on the measurement, not on confidentiality** — re-submitting the same `(judge_id, query_id, doc_key)` overwrites by design, so a judge that drifts, mistypes, or is talked into a different name either fragments its own label set or **silently overwrites another judge's**, and the agreement number that R.4 exists to produce degrades with nothing in the logs looking wrong. That is the same shape as the confused deputy one layer down: every component behaved correctly. **Why it is worth fixing before it is a security problem**: the day a second annotator is a person rather than a model, identity-as-parameter becomes a real boundary, and the fix is the same one R.5c needs anyway — derive the principal from the token and treat any identity the model can type as untrusted. The agent case is strictly worse than the ordinary API case: with a normal endpoint an attacker has to craft the request, here the field is filled by a model that can be argued with, so **prompt injection reduces the cost of impersonation to one persuasive sentence**.  **A second instance was found at the same time and has since been fixed:** `/api/ask` and `/api/ask/news` take `userId` as a request-body field defaulting to `"local-user"`, and it was written through to `spec["owner"]` — so the ownership of a created artifact was self-declared by the caller. **`quant_api` now derives the owner from the token instead** (R.5c, `fix(R.5c): take the strategy owner from the token, not from the request`). The `userId` field still exists on the quant_ai request model but the API no longer trusts it, so the remaining work is deleting a parameter that no longer does anything. The rule that covers both cases: **business arguments narrow what, the token decides who** — if a signature or request body carries `user_id`, `tenant_id`, `judge_id` or `owner`, authorization has moved into the payload. Interim mitigation without waiting for OBO: reject a `judge_id` that does not match the authenticated principal once one exists, and until then make the write reject rather than overwrite when the `(query_id, doc_key)` pair already carries a different judge
- [x] **R.5 phase 1–2** Authentication that actually enforces — `SecurityConfig` ended with `.anyRequest().permitAll()`, so three path patterns required a token and everything else was open, **including `/api/portfolio/holdings`, which served personal financial data unauthenticated** (measured: 200 before, 401 after). JWT was configured and enforcing almost nothing, which is worse than no auth because it reads as protected. **The order of work is the design**: quant_ai sent no credential at all and six of eight UI modules sent none either, so tightening the server first would have broken every page and every MCP tool at once — phase 1 made both carry a token while the server still permitted everything, phase 2 flipped the default. Adding the credential before requiring it is the only sequence with no broken window in the middle. **Read and write are split deliberately**: quant_ai holds a service-account credential broader than any single user's (the confused deputy), which cannot be removed until on-behalf-of exchange lands, but its blast radius can be — the service account has `quant-read` and not `quant-write`, so an injected agent can read the platform and **cannot record a trade**. `KeycloakRealmRoleConverter` exists because Spring's default converter reads `scope` while Keycloak puts realm roles under `realm_access.roles`; without it every `hasRole` fails closed and looks like a permissions bug. Measured after deploying — no token 401, service account 200 read / 403 write, all ten MCP tools still returning real data. Three mistakes are kept in PROJECT_PLAN rather than tidied away, because each needed a different kind of evidence to catch: **a 204 is not a token** (a role assignment the admin API accepted three times had silently granted the agent write), **a commit is not a deployment** (the UI change was never built into an image, so the browser ran a bundle with no `Authorization` header against an API that had just started requiring one), and **a passing API test is not a working UI** (`quant-read` reached service accounts but no human, and the one principal the tests exercised was the only unaffected one)

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

---

# Interview Roadmap

## A. Data Engineer Interview Roadmap

### Currently Available (can discuss directly)
- MongoDB 845K+ articles + 675M GKG inverted index (large-scale document storage + full-text search)
- Python ETL pipeline: news collection → company matching → feature build (multiple data sources, incremental/full load)
- LLM batch inference pipeline (845K articles, two passes + dual-LLM merge)
- Docker Compose multi-service orchestration (MongoDB / MySQL / Kafka / Airflow / MLflow / Qdrant)
- Airflow DAG definitions (DAG structure, task dependencies, SLA)

### Critical Gaps — Must Fill (will be asked in interviews)

| What is missing | Why it matters | Stage | Effort |
|---|---|---|---|
| Kafka has no actual producer/consumer | DE must-ask; "deployed but unused" is unconvincing | Stage 7 / 5.1.1 | 3 days |
| Airflow DAG has not actually run end-to-end | "wrote a DAG" ≠ "it ran" | Stage 7 | 1 week |
| MLflow has no actual recorded runs | Can use the tool but has no output; can't answer interview questions about run results | Stage 7 / 5.2.3 | 1 day |
| No ETL unit tests | DE interviews always ask how pipeline reliability is guaranteed | New | 3 days |
| No data quality checks | Standard for production-grade pipelines; absence raises reliability doubts | New | 2 days |
| No idempotency design doc | DE must-know: will re-running the pipeline produce duplicates? | New (add doc) | 1 day |

### Bonus Items — Stronger with, not required to interview

| Item | Value | Stage | Effort |
|---|---|---|---|
| Flink streaming pipeline | High-demand DE skill at large companies, most differentiating | 5.2.2 | 2 weeks |
| dbt data lineage | Data modeling best practice, common in FinTech DE | 5.2.4 | 1 week |
| Prometheus + Grafana monitoring | Observability, also useful for SRE interviews | 5.4 | 3 days |
| Schema Registry (Kafka) | Avro schema evolution, large-scale data governance | 5.1.1 | 2 days |
| CI/CD for data pipeline | GitHub Actions running tests + lint | New | 2 days |
| Data lineage diagram | Which tables depend on which source; can use OpenLineage | New | 3 days |

### Complete DE interview story (after filling gaps)
*"Built a financial news processing system covering 100 stocks: established full-text index on GDELT raw data (675M records); Python ETL cleaned and matched 845K articles with idempotency design and data quality checks; Airflow scheduled 5 DAGs for daily incremental updates; Kafka publishes daily trading signals (complete producer/consumer pipeline); MLflow tracked 100+ model experiments; entire system deployable with a single Docker Compose command."*

---

## B. FinTech / Quantitative Finance Interview Roadmap

### Currently Available (can discuss directly)
- Walk-forward validation (not backtest overfitting), IC=0.059 (60d), 100 symbol universe
- Multi-factor model: news quality + momentum + earnings events + LLM sentiment
- Event-driven backtest framework (min_hold=20d, +1.40% excess return, outperforming fixed holding baseline)
- LLM dual-model ensemble labeling (Gemma + Qwen + dual-LLM merge, 77.3% agreement rate)
- 845K articles with three-dimensional labels: sentiment / event type / signal strength

### Critical Gaps — Must Fill (quantitative interview essentials)

| What is missing | Why it matters | Effort |
|---|---|---|
| Sharpe ratio / max drawdown / Sortino | Must-ask for quant roles; no numbers = incomplete strategy | 2 days |
| Turnover + transaction cost model (0.05% assumption) | Is the strategy still profitable after costs? | 1 day |
| Annualized return vs SPY buy-and-hold comparison | Does the strategy beat passive holding? | 1 day |
| Factor IC decay curve (autocorrelation) | How many days until the signal expires, determines rebalance frequency | 1 day |
| Information Ratio (IC / std(IC)) | Signal stability; IC=0.059 is usable but IR must be shown | 0.5 days |
| Long-short portfolio (not just Top-N) | Standard for quant funds; long-only = incomplete | 3 days |
| Factor correlation matrix (VIF / redundancy check) | Avoid multicollinearity, model interpretability | 1 day |
| Year-by-year Sharpe + drawdown chart | Quantify risk in weak years (2022/2024) | 1 day |

### Bonus Items — Stronger with

| Item | Value | Stage | Effort |
|---|---|---|---|
| FinBERT fine-tuning (200x inference speedup) | AI+Finance crossover, unique highlight | 3.5.5 | 1 week |
| Factor attribution analysis (SHAP feature importance) | Interpretability, can demo live in interview | New | 1 day |
| Beta neutralization / market-neutral portfolio | Institutional quant standard | New | 2 days |
| Volatility-weighted position sizing (non-equal weight) | More sophisticated portfolio construction than equal weight | New | 1 day |
| Liquidity filter (market cap threshold) | Avoid small-cap slippage, real-world executability | New | 0.5 days |
| RAG news semantic search | "Semantic search + finance" highlight | 5.3.1 | 1 week |
| Multi-agent research assistant | AI engineering depth showcase | 5.3.2 | 2 weeks |
| Paper trading live verification record | Out-of-sample real-world performance, most convincing in interviews | C.6 | Ongoing |

### Complete quantitative interview story (after filling gaps)
*"Built a news-driven multi-factor model on a 100-stock tech universe: 845K articles labeled by Gemma+Qwen dual-model LLM ensemble (77.3% agreement); walk-forward validation 60d Rank IC=0.059, Information Ratio=X.X; event-driven holding framework achieved +1.40% excess return in an average of 13.7 days (after transaction costs +X.X%), annualized Sharpe=X.X, max drawdown X%, long-short annualized excess X%."*

---

## C. Project Productionization Roadmap (News Events → Buy/Sell/Hold Decisions)

### Minimum Viable Loop (do first)

#### C.1 Daily signal generation automation ✅ Done (integrated with launchd scheduler, not Airflow)
- `score_daily_signals.py` integrated into `scheduler/task.py`, runs automatically at 08:30 daily
  (`daily_symbol_features` 08:00 → `score_daily_signals` 08:30 → `track_positions` 08:40)
- Scores 100 stocks, writes results to `daily_signals` collection
- Fields: `symbol`, `trade_date`, `composite_score`, `signal_rank`, `signal_type` (LONG/NEUTRAL),
  `regime_mult`, and D-series context fields (`ah_gap`, `analyst_buy_ratio_chg_1m`,
  `inst_holding_pct_chg`, `retail_sent_score`, `macro_risk_on`, `macro_vix`, etc.)
- Note: still using launchd, not Airflow (Stage 7 / 5.2.1 Airflow migration still pending)

#### C.2 Risk metrics ✅ Done (`research/backtest/backtest_portfolio.py`)
- Available: Sharpe ratio (annualized, 4% risk-free rate), max drawdown, win rate, annualized return vs SPY
- 2026-06-16 validation results (full history 2015-2026, reusing `score_daily_signals.compute_score`):
  - 20d holding: Sharpe 0.84, annualized 25.8%, vs SPY Sharpe 0.54/12.1%
  - 60d holding: Sharpe 0.70, annualized 24.3%, vs SPY Sharpe 0.46/11.6%
- Still needed: Sortino ratio, turnover / transaction cost assumptions (see H.1; costs not yet deducted, numbers are optimistic)

#### C.3 Signal UI page ✅ Done (`SignalsPanel.tsx`)
- Displays all signals for the day, sorted by `signal_rank`, LONG/NEUTRAL labels color-coded
- Risk-on/Risk-off badge at top showing `regime_mult` (macro multiplier)
- Columns: Score / Quality / News burst / Earnings / AH Gap / Analyst Δ1m / Inst Δ
- 2026-06-16: added 3 D-series columns + regime badge (`quant_api` DailySignalEvent fields expanded in sync)
- Still needed: separate grouped display for watch list / avoid list (currently a single sorted table)

### Advanced (second priority)

#### C.4 Position tracking ✅ Done (`research/signals/track_positions.py`)
- `positions` collection records simulated holdings: `symbol`, `entry_date`, `entry_price`, `entry_score`,
  `entry_rank`, `days_held`, `current_return`/`exit_return`, `exit_trigger`
- Idempotent: each run fully rebuilds state from `daily_signals` + `stock_prices_history`
- `PositionsPanel.tsx` displays current position status + unrealized P&L (already in quant_ui)
- 2026-06-20 validation: 19 positions (16 open/3 closed), PANW +62.6% / LRCX +50.5% leading

#### C.5 Exit alerts ✅ Done + extended 2026-06-16
- Existing triggers: `max_hold` (60 days), `score_below_exit`, `sentiment_reversal`, `earnings_miss`
- **Two new D-series triggers added**: `analyst_downgrade` (`analyst_buy_ratio_chg_1m` < -10%), `inst_outflow` (`inst_holding_pct_chg` < -1% QoQ)
- Alerts written to `alerts` collection; UI red dot / email push still pending (currently script print + collection query only)

#### C.6 Paper trading record ✅ Baseline done (i.e. C.4 `track_positions.py`)
- Daily `daily_signals` Top-N used to simulate entries; unrealized P&L updated daily with real prices
- Total running days are still short; 3-6 month out-of-sample performance is accumulating (ongoing task, not one-time development)

#### C.7 ETL data quality checks ✅ Baseline done (`research/quality/data_quality_check.py`)
- Existing checks: news volume, price freshness, feature freshness, key field NULL rate thresholds
  (`quality_score`/`full_ratio`/`close`/`past_ret_20d`), signal freshness
- Integrated with scheduler to auto-run at 09:00 daily (`ENABLE_DATA_QUALITY_JOB`)
- Still needed: model training IC anomaly detection (2-sigma alert), write results to `quant_api` instead of script output only

#### C.8 ETL unit tests ✅ Done (2026-07-15)
- 90 tests, 0 failures — `pytest tests/ -q` green
- `test_feature_build.py` (29): news aggregation, LLM sentiment, quality score, date helpers
- `test_regime_scoring.py` (16): H.2 `classify_regime` (all 4 regimes + edge cases), `compute_score`
  (output columns, conviction multipliers, rank ordering), `_safe_float`
- `test_positions.py` (17): H.3 `_stop_pct` (floor/cap/passthrough), `compute_daily_vols` (≥22 bar
  requirement, constant-price zero-vol, multi-symbol), `_spearman_ic`, `build_positions` stop-loss trigger
- `test_earnings_regime.py` (28): `attach_earnings_event_features` (empty inputs, surprise_pct, beat/miss
  signals, no-symbol-overlap), `compute_regime_features` (all output columns, calm/high-VIX/SPY-trend)
- Coverage: `score_daily_signals.py` 60%, `track_positions.py` 52%, `daily_symbol_features.py` 40%

#### C.9 Factor analysis report ✅ Done (`research/backtest/factor_analysis.py`)
- Implemented: IC decay table (multi-horizon), year-by-year IC breakdown, SHAP feature importance
  (including LLM vs traditional factor contribution split)
- Updated: long-short portfolio + year-by-year Sharpe/drawdown chart implemented in `factor_analysis.py` walk-forward section ✅
- Still needed (optional enhancement): factor correlation matrix (VIF redundancy check)

### Full productionization path (time estimates)

```
Stage 7 services running end-to-end (1 week)
  → C.2 risk metrics + C.9 factor report (3 days)  ← can discuss in interview immediately
  → C.8 ETL unit tests (3 days)                    ← proves reliability in DE interviews
  → C.7 data quality checks (2 days)               ← production-grade credibility
  → C.1 daily signal automation (3 days)           ← project starts "moving"
  → C.3 signal UI page (3 days)                    ← visualized decisions
  → C.4 position tracking (1 week)                 ← real decision support
  → C.5 exit alerts (3 days)                       ← loop closed
  → C.6 paper trading (ongoing)                    ← accumulate real-world performance
  → project productionized + interview-ready ✓
```

---

## D. Research Layer Extensions (improve model quality)

### D.1 Macro Regime features ✅ Done 2026-06-16
- VIX level/percentile, 10Y interest rate, US dollar index, SPY 20-day trend
- Fields: `macro_vix`, `macro_vix_pctile_252d`, `macro_vix_change_5d`, `macro_tnx`,
  `macro_tnx_change_20d`, `macro_spy_ret_20d`, `macro_spy_above_200ma`,
  `macro_risk_on`, `macro_is_high_vol`, `macro_dxy_change_20d`
- In 2026 holdout, `macro_tnx` is the #2 ranked feature in LightGBM feature importance
- `macro_risk_on`/`macro_vix_pctile_252d` integrated into `score_daily_signals.py` as
  regime multiplier (risk-on ×1.20, high VIX ×0.85) — H.2.1 baseline implemented
- Deliverable: `collectors/macro/collector.py`

### D.2 Alternative Data — Retail Sentiment ✅ Done 2026-06-16
- Integrated StockTwits public API (no Reddit developer approval required, bypassing the registration rejection issue)
- New factors: `retail_msg_count`, `retail_bull_ratio`, `retail_sent_score`,
  `retail_sentiment_divergence` (= retail_sent_score − avg_sentiment_3d)
- Coverage starts from 2025-12 only, fill rate low (~3-4%), requires ongoing accumulation;
  2026-06-20 review: IC reversed from +0.09 to -0.10 (N still small, no conclusion yet, **weights not adjusted**)
- Deliverable: `collectors/retail/collector.py`

### D.3 Earnings filing text mining (10-K/10-Q) — Skipped
- Reason: requires LLM to parse large volumes of long text; engineering effort is high, lower priority than other D items
- Status: [ ] Not developing for now

### D.4 Analyst rating change factor ✅ Done 2026-06-16
- Finnhub `/api/v1/stock/recommendation`, accessed via `urllib` (under VPN, `requests`/`curl_cffi` failed; only `urllib.request.urlopen` works)
- New factors: `analyst_buy_ratio`, `analyst_sell_ratio`, `analyst_consensus_score`,
  `analyst_buy_ratio_chg_1m`
- Cross-sectional IC: `analyst_buy_ratio_chg_1m` 5d=+0.155 / 20d=+0.151, one of the cleanest signals in the D series
- Deliverable: `collectors/analyst/collector.py`

### D.5 Options market signals — Skipped
- Reason: CBOE PCR free historical data only goes back to 2019, cannot cover recent backtest window
- Status: [ ] Not developing for now

### D.6 Short Interest (short squeeze pressure) — Skipped
- Reason: FINRA website returns bot protection page under VPN, unable to scrape
- Status: [ ] Not developing for now

### D.7 Institutional holdings change (13F) ✅ Done 2026-06-16
- `edgartools`, tracking Vanguard/StateStreet/Fidelity holdings for the most recent 2 quarters
- New factors: `inst_holding_pct` (aggregate holding percentage across institutions), `inst_holding_pct_chg` (QoQ,
  computed separately for each institution's most recent two periods then averaged, avoiding misalignment from different institutions' disclosure cycles)
- Cross-sectional IC: `inst_holding_pct_chg` 60d=**+0.198**, strongest single factor in the D series
- In 2026 holdout, the single feature contributing most to LightGBM regression IC (IC=+0.337)
- Integrated as `inst_outflow` exit trigger in `track_positions.py`
- Deliverable: `collectors/inst_13f/collector.py`

### D.8 Pre-market / after-hours price signals ✅ Done 2026-06-16
- yfinance 1-minute data (`prepost=True`), chunked into 7-day windows to avoid "8-day limit" error
- New factors: `pm_gap`, `ah_gap`, `ah_volume_ratio` (`pm_volume_ratio` removed — yfinance pre-market volume field is always 0, cannot compute a valid ratio)
- Cross-sectional IC: `ah_gap` 5d=**+0.227**, the strongest short-term signal in the D series
- yfinance 1-minute history capped at 30 days; scheduler accumulates daily — as of 2026-06-20 there are 23 trading days
- Deliverable: `collectors/premarket/collector.py`

### D-series end-to-end integration (2026-06-16 ~ 2026-06-20)
All completed items are wired through the full pipeline:
`daily_symbol_features.py` (features) → `train_baseline_models.py` / `backtest_news_factor.py`
(training; 60d target significantly outperforms 20d; 2026 holdout IC=0.73 vs historical baseline 0.04-0.05) →
`score_daily_signals.py` (scoring weights + macro regime multiplier) → `track_positions.py`
(`analyst_downgrade`/`inst_outflow` new exit triggers) → `quant_api`/`quant_ui`
(DailySignalEvent expanded with 8 new D-series fields; SignalsPanel shows regime badge + 3 new columns).

`backtest_portfolio.py` full-history backtest (2015-2026, reusing `score_daily_signals.compute_score`):
60d Sharpe=0.70, 20d Sharpe=0.84, both outperforming SPY (Sharpe 0.46-0.54) — but these results are primarily driven by the existing LLM/earnings factors; D-series data windows are short, so their contribution to historical backtest is not yet fully reflected; true incremental impact requires attribution analysis after data accumulates.

**Ops fix**: On 2026-06-20 discovered `com.quant.scheduler` (old) and `com.quant.pipeline-scheduler`
(new) were both running as launchd jobs, causing all collection tasks to execute twice daily. The old job has been unloaded (plist moved to `~/Quant_trade_backups/`).

---

## E. Engineering Layer Completion (interview bonus / project completeness)

### E.1 REST API documentation (Swagger / OpenAPI)
- Add Swagger annotations to all `quant_api` endpoints; generate interactive documentation
- Open `/swagger-ui.html` during interview demo to directly showcase API design
- Status: [ ] Pending development (1 day)

### E.2 CI/CD Pipeline (GitHub Actions)
- Auto-run on every push: Python lint (ruff) + unit tests + Docker build
- main branch protection: PRs must pass CI before merging
- Status: [ ] Pending development (2 days)

### E.3 Docker image version management
- Tag quant_api / quant_ui / quant_data images with git commit hash
- docker-compose pins versions, no `latest` tag
- Support one-command rollback to previous stable version
- Status: [ ] Pending development (1 day)

### E.4 K8s deployment configuration
- Convert docker-compose to Kubernetes YAML (Deployment / Service / ConfigMap)
- No need to actually run K8s; having the config files is enough for interviews
- Bonus for DE / Platform engineer interviews at large companies
- Status: [ ] Pending development (3 days)

### E.5 Data lineage diagram (OpenLineage)
- Use OpenLineage or hand-written lineage JSON to describe:
  `news_articles` → `company_match` → `news_articles_company_matched_v2`
  → `daily_symbol_features_company_matched_v2` → `daily_signals`
- Visualize data flow; a common DE interview topic
- Status: [ ] Pending development (2 days)

### E.6 WebSocket real-time push
- When a position triggers an exit condition, UI pops an alert in real time (no page refresh needed)
- Spring Boot WebSocket + quant_ui frontend subscribe
- Corresponds to the WebSocket infrastructure for 5.1.2 Backtest orchestration API
- Status: [ ] Pending development

### E.7 Project README + architecture diagram
- Write a complete README: project background, architecture diagram, quick start, key metrics
- Architecture diagram: data flow → feature engineering → model → signals → UI
- Required before any interview; first impression on GitHub
- Status: [x] Done (2026-07-15) — `quant_docker/README.md` with the layered architecture diagram

### E.9 UI Intraday Price Chart

**Goal**: Add a price chart to the signal/position panels in `quant_ui` so users can see intraday price action alongside signal scores.

**Design:**
- Use **TradingView Lightweight Charts** (open-source, MIT license, no CDN dependency — bundle inline)
- Data source: Alpaca historical bars API (intraday 1h, up to 2 years; no need to store hourly data in own MongoDB)
- Display: overlay signal entry date (green arrow) + stop-loss level (red dashed line) on the price chart
- Placement: expandable panel below each position row in `PositionsPanel.tsx`; also available in `SignalsPanel.tsx` on click

**What is NOT needed:**
- Storing hourly bars in MongoDB — Alpaca API serves them on-demand
- Any change to the Python pipeline — purely a frontend + quant_api thin adapter
- Historical hourly data for backtesting — current strategy is 5–60d, intraday features not used

**Development steps:**
1. `quant_api`: add `GET /api/v1/prices/{symbol}/intraday?period=3m&interval=1h` — calls Alpaca bars API, returns OHLC JSON (0.5 day)
2. `quant_ui`: install `lightweight-charts` npm package; create `PriceChart.tsx` component (1 day)
3. Wire chart into `PositionsPanel.tsx` (expandable on row click) + `SignalsPanel.tsx` (1 day)
4. Overlay: entry date vertical line, stop-loss horizontal line, signal score color band (0.5 day)

**Note on automated trading**: For live order execution, intraday stop-loss monitoring uses Alpaca WebSocket real-time quotes — not stored hourly bars. Historical hourly bars are only needed if the strategy itself uses intraday features (it does not currently).

- Status: [ ] Pending (3 days)

---

### E.10 Inference Node Health Check + Failover

**Context**: LLM/SLM inference runs on a dedicated GPU node (Windows, Ryzen 9800X + RTX 5090 + 96G, LM Studio at `192.168.31.226:1234`); the Mac pipeline calls it via `SLM_API_URL`. A local fallback LM Studio exists on the Mac (`127.0.0.1:1234`) but switching is manual today. The SLM filter already degrades to pass-through when no endpoint responds — failover should try the local node *before* giving up.

**Goal**: automatic endpoint selection so labeling jobs keep running when the GPU node is offline.

```
resolve_slm_endpoint():
    for url in [SLM_API_URL_PRIMARY (5090 node), SLM_API_URL_FALLBACK (local)]:
        GET {url}/models with 2s timeout → healthy? return url
    return None → existing pass-through degradation
```

**Implementation**:
1. Shared helper in `slm_filter.py` / `llm_enrich_articles.py`: probe on startup + re-probe on connection error (cached 60s)
2. Log which endpoint served each batch (throughput differs ~5×; needed for run-time estimates)
3. Optional: Slack alert on failover so silent GPU-node outages are visible

**Interview value**: turns the multi-node setup into a defensible story — "heterogeneous GPU offload with health-checked failover and graceful degradation".

- Status: [ ] Pending (1 day)

---

## F. AI Engineering Layer (AI Engineer / MLE interview bonus)

### F.1 Prompt Engineering evaluation framework
- Compare labeling accuracy of different prompt templates (use 100 manually-annotated articles as ground truth)
- Output evaluation report: precision / recall / confusion matrix (event_type classification)
- Proves the LLM pipeline is "validated", not just run arbitrarily
- Status: [ ] Pending development (2 days)

### F.2 Vector database news semantic search (RAG)

> **Superseded by R.1–R.4.** This entry claimed "Qdrant already deployed" — that was never
> true; there is no `qdrant` service in `docker-compose.yml`. The scope also stopped at a
> search box, which is the part that does not answer the depth question. Kept for the UI
> surface only; the retrieval work itself now lives in the R-series.

- Endpoint: `/search?q=NVIDIA earnings beat Q3` → relevant articles + LLM summary
- Search box in quant_ui, served by the R.2 hybrid retriever
- Status: [ ] Pending — retrieval moved to R.1/R.2/R.3; this is the UI layer on top (1 day, after R.2)

### F.3 Model interpretability report (SHAP)
- Run SHAP analysis on LightGBM model
- Output: factor contribution ranking, per-stock prediction explanation (why AAPL gets a high score)
- Interview demo killer: not just "IC=0.059" but also "driven primarily by avg_sentiment_5d and earnings_recency_weight"
- Status: [x] Done — `research/backtest/factor_analysis.py`

### F.4 Multi-Agent research assistant (LangGraph)
Extend the existing `quant_langchain` container from LLMChain to a LangGraph stateful agent graph.

**Agent architecture (4-node graph):**
```
User input: "Analyze recent NVDA news and give a trading recommendation"
    ↓
data_agent      → calls quant_api to fetch news + price + sentiment factors
    ↓
analysis_agent  → reads IC ranking + sentiment distribution, LLM interprets recent events
    ↓
strategy_agent  → generates entry/exit rules (combining LLM scores + quantitative signals)
    ↓
risk_agent      → position sizing, stop-loss conditions, final output: position recommendation JSON
```

**Current state (existing foundation):**
- `quant_langchain/main.py`: placeholder endpoints `/api/workflow/generate-spec` and `/api/workflow/generate-tasks` already exist, but only do prompt → JSON with no execution capability
- `quant_api/StrategyService.java`: already calls langchain-agent; can directly serve as tools server
- Missing: LangGraph agent loop, tool registration, state persistence

**Development steps:**
1. Install langgraph, refactor `quant_langchain/main.py` (2 days)
2. Register tools: `search_news(symbol, days)` → calls quant_api; `get_features(symbol)` → MongoDB; `run_backtest(rules)` → Python
3. Implement 4-node graph + state passing (2 days)
4. Add ReAct loop: analysis_agent can decide whether it needs more data (1 day)
5. Integrate Qdrant RAG (after F.2 is done): data_agent can semantically search relevant news (1 day)

**Demo flow (for interviews):**
- Input: "Has AAPL had any negative news in the last 30 days? Should I hold a position now?"
- data_agent fetches news + sentiment distribution
- analysis_agent finds `avg_sentiment_5d = -0.3`, identifies regulatory risk event
- strategy_agent recommends "wait and watch; build position after sentiment recovers"
- risk_agent adds: if holding, stop-loss at -3%, max position size 5%

**Interview value:** covers ReAct reasoning + tool use + state graph — core competency for MLE / AI Engineer roles
- Status: [ ] Pending development (2 weeks)

### F.6 Upgrade rule_validator to a real Agent (ReAct loop)
**Current state:** `quant_data/tools/rule_validator_agent.py` has a prototype of "LLM judges → tool call → re-judges", but the sequence is hardcoded with no reasoning loop.

**Upgrade direction:**
- Validation failure → agent autonomously decides: fetch more articles / modify prompt / mark as ambiguous
- When handling ambiguous names from `ambiguous_names.py`, agent proactively searches for company background to decide
- Change from "pipeline" to "ReAct agent with memory"

**Development steps:**
1. Rewrite `rule_validator_agent.py` with LangGraph; add tools: `fetch_article(url)`, `search_web(company)`, `label_ambiguous(name, reason)`
2. Agent decides on its own whether more evidence is needed, up to N steps
3. Output trace: which steps each rule validation went through and the final reasoning basis

- Status: [ ] Pending development (3 days)

### F.7 Airflow adaptive scheduling Agent
**Current state:** All 4 DAGs in `airflow/dags/` are static time-triggered, with no adaptive capability.

**Upgrade direction:**
- Add `quality_monitor_dag`: after the pipeline runs each day, agent analyzes:
  - Is news volume abnormally low? (data source down?)
  - Is LLM label disagreement rate increasing? (model degradation?)
  - Has signal IC been declining for 5 consecutive days? (needs retraining?)
- Agent outputs decision: trigger re-run / switch to stronger model / send alert / auto-submit retraining job

**Development steps:**
1. Create `quality_monitor_dag.py`; BranchPythonOperator decides based on metrics (1 day)
2. Add LLM decision node: send anomaly metric summary to LLM, output recommended action (1 day)
3. Integrate Kafka: agent decision → publish to topic → downstream consumes (1 day)

- Status: [ ] Pending development (3 days)

### F.8 LLM annotation active learning Agent (disagreement sample handling)
**Current state:** Gemma + Qwen disagreement rate is 22.7%; merged blindly by the dual-LLM reconciler (`merge_ab_labels.py`).

**Upgrade direction:**
- For high-uncertainty samples where label_model_probs < 0.7, agent actively intervenes:
  - Sends the original text + both model outputs together to a stronger LLM (Qwen3-27B / GPT-4o)
  - Agent produces the final label + explanation ("model A mislabeled because the article is about earnings, not a company event")
  - Added as hard negative examples to the FinBERT training set
- Expected: disagreement sample accuracy improved from ~60% to ~85%

**Development steps:**
1. Filter samples where `llm_disagreement=1 AND llm_label_model_probs < 0.7` (~190K records)
2. Write `active_learning_agent.py`: batch-submit to stronger model, parse output, write back to MongoDB
3. Update `llm_sentiment_final` field, rerun feature build
4. Compare IC before and after

- Status: [ ] Pending development (4 days)

### F.5 FinBERT fine-tuning (3.5.5)
- Train on Gemma+Qwen consensus labels (~650K samples)
- Three heads: sentiment regression + event_type 7-class + signal_strength 3-class
- Inference speed: ~3.9 art/s → ~1000+ art/s (200x speedup)
- Status: [ ] Pending development (1-2 weeks)

### F.9 Rule Optimization Agent (Iterative Self-Improving Loop)

**Goal**: After news collection, automatically evaluate collection quality by stratified sampling across years, computing precision/recall with an LLM judge, diagnosing failure modes, modifying rules, and repeating — converging on optimal rules without manual tuning.

This directly addresses the known SLM Phase 3 "incidental mention" false positive problem (Morgan Stanley survey cited in Apple articles, da Vinci art in ISRG articles, etc.) and eliminates the need for manual rule maintenance.

**Agent architecture (4-phase loop):**

```
Round N:
  ┌─ Sampler    → stratified sample: 10 articles × 10 years × target symbols
  ├─ Evaluator  → LLM judge (Claude/GPT-4o) labels each: TP / FP / FN
  ├─ Diagnoser  → groups errors by failure type:
  │               - incidental mention FP
  │               - wrong company FP (similar name)
  │               - relevant article FN (missed match)
  │               - rule too aggressive (over-filtered)
  └─ Modifier   → proposes rule changes; applies them; logs diff

Repeat up to 10 rounds; stop when F1 improvement < 1% between rounds.
```

**What can be modified per round:**
| Rule layer | Modification type |
|---|---|
| SLM Phase 3 prompt (`slm_filter.py`) | Strengthen "primary subject" constraint; add incidental-mention examples |
| `ambiguous_names.py` entries | Add/remove disambiguation entries for specific symbols |
| Relevance threshold | Adjust score cutoff per symbol type (large-cap vs small-cap) |
| Special per-symbol rules | Add blocklist keywords that generate systematic FPs |

**Ground truth strategy:**
- Primary judge: Claude Opus (silver standard; low cost per article, fully automated)
- Escalation: articles where judge confidence < 0.7 → flag for human review
- Batch size: 100 articles per round (10/year × 10 years); full evaluation costs ~$0.50/round

**Sampling strategy:**
```python
# Stratified sample: balanced across years and symbols
years = range(2015, 2025)          # 10 years
articles_per_year = 10             # 10 per year = 100 total per round
symbols_sampled = 5                # rotate symbols each round to avoid overfitting
# → 100 articles judged per round × 10 rounds = 1000 total labels
```

**Output per round:**
- Accuracy report: precision / recall / F1, broken down by year and by error type
- Rule diff: unified diff of what changed vs previous round
- Convergence tracker: F1 trend across rounds (stop condition: ΔF1 < 1%)

**Stored in MongoDB:**
```json
{
  "round": 3,
  "timestamp": "2026-07-15T10:00:00Z",
  "metrics": { "precision": 0.87, "recall": 0.91, "f1": 0.89 },
  "error_breakdown": { "incidental_mention_fp": 6, "wrong_company_fp": 2, "fn_missed": 4 },
  "rules_changed": ["slm_filter.py prompt v3", "ambiguous_names: +MSFT_survey_blocklist"],
  "sample_ids": ["article_id_1", "..."]
}
```

**Development tasks:**
1. `tools/rule_optimizer_agent.py` — main agent loop (LangGraph or simple Python loop)
2. `tools/news_sampler.py` — stratified sampling from `news_articles_company_matched_v2`
3. `tools/llm_judge.py` — call Claude API, parse TP/FP/FN verdict + reason
4. `tools/rule_modifier.py` — apply proposed changes to SLM prompt / ambiguous_names.py, write diff to MongoDB
5. `tools/accuracy_reporter.py` — compute metrics, print round summary, decide continue/stop
6. Integrate into `scheduler/task.py` as a weekly or on-demand job

**Execution modes:**
- `--mode eval` (evaluation only; no rule changes) — runs before any deploy to get baseline
- `--mode optimize` (full loop; modifies rules) — run after adding new symbols or when FP rate spikes
- `--mode audit --round 3` (inspect a specific round's samples and verdicts)

**Interview framing:**
*"Built a self-improving news validation agent that iteratively samples historical articles across 10 years, evaluates relevance with an LLM judge, diagnoses failure modes (incidental mention FP, wrong-company FP, missed matches), and modifies SLM prompts and disambiguation rules — converging from F1=0.XX to F1=0.XX in 10 rounds."*

**Relates to:** F.6 (rule_validator ReAct), F.8 (active learning), project_slm_optimization (incidental mention FP)

- Status: 🟡 Developed, not yet tested (2026-07-13)

---

### F.10 Strategy Studio → Backtest Execution Pipeline

**Goal**: Close the loop on the existing Strategy Studio UI (quant_ui `StrategyStudio.tsx`). Currently the UI generates StrategySpec JSON + Tasks JSON + Strategy XML via LLM and saves them to the DB — but nothing executes them. This item wires the saved strategy into the existing Python backtest engine so users get real P&L results back in the UI.

**Current state:**
- `quant_ui/src/pages/StrategyStudio.tsx`: full prompt → spec → tasks → XML → save flow already works
- `quant_ai` (localhost:18000): generates StrategySpec/Tasks/XML via local LLM
- `quant_api/StrategyService.java`: `/api/v1/strategies/save` stores to MySQL
- **Missing**: a run-backtest endpoint that parses the saved strategy and routes to Python backtest

**Design:**

```
User clicks "Run Backtest" in Strategy Studio UI
    ↓
POST /api/v1/strategies/{id}/backtest  (quant_api)
    ↓
StrategyService.java parses StrategySpec JSON:
  - instruments (e.g. ["AAPL", "MSFT"])
  - entry_rule  (e.g. "rsi_14 < 30" or "avg_sentiment_5d > 0.3")
  - exit_rule   (e.g. "rsi_14 > 70" or "stop_loss: 0.05")
  - horizon_days, lookback_years
    ↓
Triggers Python subprocess or HTTP call:
  research/backtest/backtest_portfolio.py  (signal-based strategies)
  research/backtest/backtest_event_driven.py  (event-driven strategies)
    ↓
Returns to UI: Sharpe, annualized return, max drawdown, hit rate
```

**Development steps:**
1. **StrategySpec parser** (`research/strategy_runner.py`): read JSON spec, map `entry_rule` field to existing signal columns in `daily_symbol_features`; validate that required features exist (1 day)
2. **Backtest adapter**: wrap `backtest_portfolio.py` so it accepts a StrategySpec dict instead of hardcoded parameters; add `--spec-file` CLI flag (1 day)
3. **quant_api endpoint**: `POST /api/v1/strategies/{id}/backtest` → call Python subprocess, poll result, return metrics JSON (1 day)
4. **UI result panel**: add "Run Backtest" button + result card below Save Result in `StrategyStudio.tsx` showing Sharpe/return/drawdown (0.5 day)

**Scope constraint**: Only support strategies whose `entry_rule` maps to existing feature columns (avg_sentiment_5d, rsi, etc.) — not arbitrary code execution. This keeps scope tight while making the demo fully functional.

**Interview framing:**
*"Built a full natural-language → backtest pipeline: user describes a strategy in plain English, the local LLM (via LM Studio) generates a structured StrategySpec, which is then executed against 5 years of historical data using the existing walk-forward backtest engine, returning Sharpe / drawdown / hit rate directly in the UI."*

- Status: [ ] Pending (3-4 days)
  - `tools/llm_judge.py` — LLM judge (Claude API + local SLM fallback, TP/FP + fp_type + regex proposal)
  - `tools/rule_optimizer.py` — main loop (sample → judge → diagnose → propose → patch → repeat)
  - `collectors/news/gdelt/special_rules/ambiguous_names.py` — patch loader added (merges `tools/rule_optimizer_patches.json` at init)

---

### F.11 News Pre-filter SLM (Fast Relevance Triage)

**Goal**: Add a lightweight binary classifier before the expensive Gemma+Qwen dual-pass pipeline to discard obviously irrelevant GDELT articles early, reducing LLM inference load by ~70%.

**Design**: Fine-tune a tiny SLM (e.g. `distilbert-base-uncased`, 66M params) on the existing labeled set where both Gemma and Qwen agree (`llm_sentiment_final` non-null + `llm_disagreement=0`). Binary output: relevant / irrelevant. Articles classified as irrelevant skip the dual-LLM pass entirely.

**Expected impact**: ~70% of GDELT articles are low-quality noise; filtering these reduces dual-LLM cost without degrading labeled dataset quality.

- Status: [ ] Pending (3 days)

---

### F.12 Signal Explanation Generation (SLM → UI)

**Goal**: For each stock with a high signal score today, auto-generate a 2-sentence plain-English explanation of *why* — visible in the Signals UI panel.

**Example output**: *"NVDA scores 87/100 today. Institutional holdings increased 2.1% QoQ (strongest factor) and avg_sentiment_5d hit +0.42 following multiple positive data center coverage articles."*

**Implementation**: After `score_daily_signals.py` runs, pass top-N stocks' feature values to local SLM (Qwen 3.5 9B via LM Studio) with a prompt template → store explanation string in `daily_signals` MongoDB collection → `quant_api` exposes it → `SignalsPanel.tsx` renders inline.

- Status: [ ] Pending (2 days)

---

### F.13 Morning Briefing Agent (Daily Pre-market Summary)

**Goal**: Every trading day at 07:00 (before market open), auto-generate a short briefing for currently held positions: overnight news, regime status, any exit warnings.

**Output example**:
```
Morning Briefing — 2026-07-15 07:00

PANW (+62.6% unrealised) — No material news overnight. Regime: RISK_ON.
LRCX (+50.5%) — 2 articles mentioning inventory correction risk. Consider monitoring.
Regime: RISK_ON (macro_vix_pctile=0.22, macro_risk_on=1)
Exit alerts today: None
```

**Implementation**: `scheduler/task.py` new job at 07:00 → fetch held positions + overnight GDELT + regime → prompt local SLM → write to `daily_briefings` collection → push to UI + optional email.

- Status: [ ] Pending (2 days)

---

### F.14 Earnings Surprise Prediction Agent

**Goal**: In the 10-day window before a company's earnings date, aggregate news sentiment + analyst consensus trend + historical surprise patterns → LLM produces a beat/miss probability estimate as an additional signal.

**Input features per stock:**
- `avg_sentiment_5d/10d` (news tone heading into earnings)
- `analyst_buy_ratio_chg_1m` (analyst momentum)
- `days_to_earnings` (0–10 window)
- Historical `surprise_pct_last` (prior 4 quarters)

**Output**: `pre_earnings_beat_prob` (0–1) stored in `daily_symbol_features`; used as an additional factor in `score_daily_signals.py`.

**Backtest**: compare pre-earnings beat_prob vs actual surprise_pct — if IC > 0.05 across 100 symbols, add to model.

- Status: [ ] Pending (3 days)

---

### F.15 SEC EDGAR + Earnings Transcript RAG

**Goal**: Extend `quant_ai` RAG to cover SEC filings and earnings call transcripts, enabling natural language queries like "What did NVDA management say about data center margins last quarter?"

**Two sub-components:**

1. **SEC EDGAR RAG**: Use `edgartools` (already a dependency) to pull 10-K/10-Q risk factor sections → chunk → embed → store in Qdrant (separate collection from news)
2. **Earnings transcript RAG**: Pull transcripts from Seeking Alpha / Motley Fool → chunk management commentary → embed → Qdrant

**Integration with quant_ai**: Extend `/api/ask` to route queries: news questions → news collection; filing questions → edgar collection; transcript questions → transcript collection. Use query classification with a small routing prompt.

- Status: [ ] Pending (depends on F.2 Qdrant RAG; 3 days after F.2)

---

### F.16 Real-time News Monitoring Agent

**Goal**: Instead of waiting for the nightly GDELT batch, continuously monitor news feeds for currently held positions and trigger instant alerts on major negative events.

**Architecture**:
```
Every 30 min (launchd job)
    ↓
Poll NewsAPI / Finnhub news feed for held symbols
    ↓
SLM relevance filter (F.11) → discard noise
    ↓
LLM sentiment score → if negative_event_count spike detected
    ↓
Write to alerts collection → push to quant_ui (WebSocket, E.6)
```

**Trigger condition**: `avg_sentiment_3d` drops > 0.3 units from prior reading, or `negative_event_count` spike of 3+ articles in one session.

- Status: [ ] Pending (3 days)

---

### F.17 Portfolio Manager Agent (Rebalancing Recommendations)

**Goal**: After daily signals are scored, an LLM agent synthesizes current positions + new signals + regime → outputs a structured rebalancing recommendation.

**Agent output format**:
```json
{
  "add": [{"symbol": "NVDA", "reason": "score 89, regime RISK_ON, no exit signals"}],
  "reduce": [{"symbol": "LRCX", "reason": "score dropped to 41, inst_outflow trigger"}],
  "hold": ["PANW", "AMZN"],
  "regime_note": "RISK_ON — increase conviction on high-score positions"
}
```

**Revised design (2026-07-26) — review layer, not replacement**

The output format above assumed the agent decides. It should not. `track_positions.py`
already decides entries, exits, stops and holding periods deterministically, and a local
9B model would be both worse and non-reproducible at that job. Replacing tuned rules with
an LLM is a step backwards, and "why do you think the model beats your rules" is a
question with no good answer.

The agent reviews the rule engine's decisions instead, covering the two things rules
structurally cannot do:

1. **Read why a price moved.** A stop fires at −8%; the rule sees only the number. The
   agent pulls the news (I.6) and can distinguish a sector-wide selloff that has already
   reversed — a whipsaw exit — from a company-specific failure.
2. **Reason about the portfolio.** The rules are per-position. Nothing asks whether four
   of five holdings are semiconductors, or whether total exposure suits a RISK_OFF regime.

**Output**: a decision table, one row per rule action — `agree` / `flag`,
`target_weight_pct`, confidence, reasoning, and `evidence[]` where each entry is a
`(tool, field, value)` triple. Machine-consumable, so G.1 can later execute it.

**Three deterministic gates after the model replies** — none of them trust the model:
- **Schema** — valid JSON, typed fields, `action` in enum, weight in 0–100. One repair
  round-trip with the specific error, then fail loudly rather than emit garbage.
- **Grounding** — every cited `(tool, field, value)` must appear in a real observation
  from this run (float tolerance). Citations that do not are dropped with the
  recommendation. The point is not to ask the model to avoid inventing numbers; it is to
  make invented numbers non-viable.
- **Business rules** — symbol in the 100-name whitelist, ≤5% per position, exits only
  against something actually held.

**Depends on**: P.1 (a real portfolio to review), I.6 (news the agent can read).
Evaluated by F.22.

**Implementation**: `quant_ai/portfolio_agent.py` reusing `mcp_client`; no changes to
`agent.py`, `mcp_server.py`, or `mcp_client.py`. LangGraph is not needed — the existing
hand-written loop plus a validator is smaller and easier to test.

- Status: [x] Done (2026-07-27) — `portfolio_agent.py`, 448 lines; review layer over the rule engine with schema/grounding/business gates and 25 unit tests

---

### F.22 Agent Evaluation Harness

**Goal**: Answer "how do you know the agent is any good" with numbers instead of a demo.

**What cannot be evaluated**: whether a recommendation makes money. That needs the market
to pass. Claiming otherwise would be dishonest.

**What can be evaluated** — and these are the failure modes that actually keep agents out
of production:

| Metric | Definition |
|---|---|
| Schema validity | passed first try / passed after one repair / failed |
| **Grounding rate** | cited evidence that is real ÷ total citations |
| Tool recall | required tools that were called |
| Tool precision | called tools that were required |
| Stability | Jaccard overlap of the recommendation set across N runs of one input |
| Cost | steps, wall-clock, tokens |

The existing 7 unit tests mock the LLM, so they prove the loop is correct — not that the
decisions are. This closes that gap.

**Baseline**: the rule engine. The agent's job is not to differ from it; it is to be
justifiably different when it does. Agreement rate is itself a signal — too high and the
agent adds nothing, too low and it cannot be trusted.

**Implementation**: `quant_ai/eval/cases.yaml` (golden cases: prompt, required tools,
forbidden tools, schema, assertions) and `quant_ai/eval/run_eval.py` producing a report.

- Status: 🟡 Written, not fully run — `eval/run_eval.py` + `eval/cases.yaml` exist; the full 15-run pass on the local 9B was deferred (~1h)

---

### F.18 Backtest Reflection Agent

**Goal**: After each backtest run, an LLM agent automatically analyzes weak years (2022, 2024) and generates a diagnostic report with hypotheses for why the signal failed.

**Input**: year-by-year IC + Sharpe table (already produced by `factor_analysis.py`) → LLM reads the numbers and produces: "2022 failure likely driven by macro regime shift (VIX spike); macro_vix_pctile feature had negative IC that year — consider regime-conditional model."

**Output**: `backtest_reflections` MongoDB collection + downloadable PDF from UI.

- Status: [ ] Pending (2 days)

---

### F.19 LLM Factor Hypothesis Generator

**Goal**: Given the current IC table + feature correlation matrix, prompt an LLM to suggest new factor ideas not yet in the feature set.

**Prompt input**: current top/bottom IC factors, known failure modes (2022/2024), sector composition of universe.

**Expected output**: list of 5–10 testable hypotheses, e.g. "options implied volatility spread could predict 20d returns for high-beta names" or "google search trend spike 3 days before earnings beats".

**Workflow**: human reviews suggestions → select 1–2 → implement → backtest → add to model if IC > 0.05.

- Status: [ ] Pending (1 day — prompt engineering + review loop, no code pipeline needed)

---

### F.20 Dip-Buy Scanner Agent (Contrarian Entry Candidates)

**Goal**: Monitor a watchlist (held positions + custom list). When a stock is hammered by a wave of negative news or a weak earnings report, decide whether the drawdown is a *sentiment washout* (buyable dip) or *structural deterioration* (falling knife), and generate contrarian entry candidates.

**Trigger signals (all source data already collected)**:

| Signal | Source | Condition |
|---|---|---|
| Negative-news burst | `news_articles_company_matched_v2` LLM sentiment | negative article count over N days ≫ per-symbol baseline AND `avg_sentiment_5d` below threshold |
| Earnings miss | `analyst_consensus` + price data | EPS/revenue miss vs consensus, or guidance cut |
| Price washout | `stock_prices_history` | N-day drawdown > X%, sector-relative (exclude broad selloffs) |

**Agent core — dip vs falling knife triage**: an LLM reads the clustered negative articles and classifies the cause: one-off event (lawsuit, recall, single miss, sector-wide sentiment contagion) → dip candidate; structural (demand collapse, business model impairment, repeated guidance cuts) → reject. Output includes the reasoning and evidence articles.

**Output**: `dip_candidates` MongoDB collection + Slack alert (existing `send_alert` pipeline) + UI card:
```json
{
  "symbol": "PYPL",
  "drawdown_20d": -0.23,
  "neg_articles_5d": 18,
  "avg_sentiment_5d": -0.41,
  "sentiment_fading": true,
  "triage": "sentiment_washout",
  "reasoning": "Selloff driven by one-off FTC inquiry headlines; revenue guidance unchanged; negative article count decaying since day 3.",
  "watch_zone": "entry interest below 52.0 (61.8% retrace of gap)"
}
```

**Scheduling**: new DAG `quant_dip_scanner`, daily after `quant_daily_pipeline` features complete (~08:30); optional intraday re-check reusing F.16's 30-min polling.

**Phased implementation**:
1. Phase 1 — rule-based detector (no LLM): 3-signal filter → candidate list → Slack (1–2 days)
2. Phase 2 — LLM triage layer (dip vs knife) via LM Studio (2 days)
3. Phase 3 — calibrate with backtest engine: historical win rate of "20d rebound after negative-burst" → tune thresholds (2 days)
4. Phase 4 — merge into F.17 Portfolio Manager Agent as its contrarian-entry submodule

- Status: [ ] Pending (Phase 1–2 ≈ 4 days; overlaps F.14 earnings data and F.16 monitoring loop)

---

## I. MCP Integration

MCP (Model Context Protocol) standardizes how LLM clients interact with external tools and data. Adding MCP to this platform enables any MCP-compatible client (Claude Desktop, Claude Code, custom agents) to directly query signals, news, positions, and trigger backtests via natural language — with no custom API integration needed on the client side.

### I.1 quant_mcp_server — Core Platform MCP Server

**Goal**: Expose the quant platform as an MCP server so Claude or any MCP client can query live trading data through tool calls.

**MCP tools exposed:**

| Tool | Description |
|------|-------------|
| `get_signals(date?)` | Returns today's top-N signal scores, regime, signal_type |
| `get_news(symbol, days)` | Returns recent labeled articles for a symbol |
| `get_positions()` | Returns current paper positions + unrealized P&L |
| `get_factor_ic(factor?, horizon?)` | Returns IC table for a factor or all factors |
| `get_regime()` | Returns current macro regime + VIX / SPY trend |
| `run_backtest(spec_json)` | Triggers Python backtest, returns Sharpe/return/drawdown |
| `get_briefing(date?)` | Returns today's morning briefing text |

**MCP resources exposed:**
- `daily_signals` — subscribable resource; clients receive push when new signals are written

**Implementation**: Python `mcp` SDK (`pip install mcp`); standalone FastAPI server on port 18002; reads directly from MongoDB. Register in Claude Desktop `claude_desktop_config.json` for local use.

 - Status: [x] Done — six read-only tools over stdio, served through quant_api with a mongo fallback

---

### I.2 Claude Desktop Integration

**Goal**: Connect `quant_mcp_server` to Claude Desktop so daily trading analysis can happen in a normal Claude conversation — no custom UI needed.

**Usage after setup:**
> *"What's the current signal for NVDA?"* → Claude calls `get_signals()` via MCP → returns live score
> *"Show me all positions with unrealized loss"* → Claude calls `get_positions()` → filters + explains
> *"Run a backtest for a strategy that buys on avg_sentiment_5d > 0.4"* → Claude calls `run_backtest()`

**Setup**: Add `quant_mcp_server` entry to `~/Library/Application Support/Claude/claude_desktop_config.json`.

**Interview value**: "The platform is MCP-native — any Claude client can query live signals and positions without writing a single line of integration code."

 - Status: [x] Done — registered in claude_desktop_config.json, verified over the real MCP protocol

---

### I.3 Alpaca Order Execution via MCP

**Goal**: Extend `quant_mcp_server` with order execution tools so an LLM agent can read signals AND place orders through the same MCP interface — creating a true AI-driven trading loop.

**Additional MCP tools:**

| Tool | Description |
|------|-------------|
| `place_order(symbol, qty, side)` | Submit paper/live order to Alpaca; enforces pre-trade guardrails |
| `cancel_order(order_id)` | Cancel an open order |
| `get_account()` | Returns Alpaca account equity, buying power, positions |

**Safety**: All order tools enforce the same guardrails as G.1 (max 5% position, kill-switch, whitelist-only). LLM cannot bypass these — guardrails are in the MCP server, not in the prompt.

**Integration with G.1**: G.1 `live_trader.py` and this MCP tool share the same order execution logic; MCP is just an additional interface to the same engine.

- Status: [ ] Pending (2 days; requires G.1 broker integration first)

---

### I.4 External Data MCP Tools (Finnhub / EDGAR / News)

**Goal**: Wrap external data sources as MCP tools so LLM agents can autonomously decide what data to fetch during analysis — instead of hardcoding API calls.

**Tools:**

| Tool | Source | Description |
|------|--------|-------------|
| `search_news(query, days)` | NewsAPI / GDELT | Full-text news search |
| `get_earnings_calendar(symbol)` | Finnhub | Next earnings date + estimates |
| `get_analyst_ratings(symbol)` | Finnhub | Current buy/sell/hold breakdown |
| `get_sec_filing(symbol, form)` | SEC EDGAR | Pull latest 10-K or 10-Q text |
| `get_price_history(symbol, period)` | yfinance | OHLCV history |

**Value**: Agents (F.4 LangGraph, F.17 Portfolio Manager) can call these tools autonomously during reasoning, rather than having all data pre-loaded into context — reduces token usage and increases flexibility.

- Status: [ ] Pending (2 days)

---

### I.5 MCP Inter-service Communication

**Goal**: Replace the current `quant_ai → quant_api` REST calls with MCP protocol, so quant_ai becomes a proper MCP client that discovers and calls quant_api capabilities dynamically.

**Current state**: `quant_ai/main.py` hardcodes `requests.get("http://quant_api:18081/api/v1/signals/daily")` — tightly coupled.

**MCP version**: `quant_ai` connects to `quant_mcp_server` via MCP client; tool discovery is automatic; adding a new quant_api endpoint just requires registering a new MCP tool — no quant_ai code change needed.

**Interview value**: Demonstrates understanding of MCP as a service mesh protocol for AI systems, not just a chatbot feature.

 - Status: [x] Done — quant_ai's agent is an MCP client (mcp_client.py); quant_mcp was folded into quant_ai

---

### I.6 `search_news` — full-text search over labeled articles

**Goal**: Let a client read the articles, not just the average.

**Current state**: every tool on the server returns a pre-computed aggregate. A client can learn that AAPL averaged +0.31 sentiment over 90 days; it cannot read one headline behind that number, cannot ask what happened on the day of a drawdown, and has no way to check whether the aggregate is driven by ten articles or ten thousand.

**Tool**: `search_news(query, symbol=None, from_date=None, to_date=None, limit=20)` over the 845K labeled articles in `news_articles_company_matched_v2`, returning headline, date, source, `llm_sentiment_final`, and `llm_disagreement`. Needs a text index on title/body.

**Why it matters**: this is the difference between a server that reports conclusions and one that can be interrogated. It is also what lets F.17 explain a stop-loss — a mechanical rule sees −8%, only an article says whether that was a sector selloff or a company-specific failure.

- Status: [x] Done — `search_news` in `mcp_server.py`; full-text over the labeled corpus,
  weighted title:10 content:1. **Verified against the deployed API on 2026-08-03, not
  against the repository.** It had been marked done a day earlier on the evidence that the
  function existed in `mcp_server.py`, while `/api/news/search` returned 404 in the running
  container: the endpoint was in the Java source but the container was running
  `quant_api:9307bbe` against a compose file declaring `e70b3cb`, so the tool was broken for
  all three MCP clients. **A file in the repository is not a working feature** — which is
  the same class of drift that status pass was meant to fix, committed in the same pass.

---

### I.7 `get_feature_history` — feature time series

**Goal**: Make trends visible. `get_stock_features` returns only the latest row, so "is sentiment improving or deteriorating" is unanswerable today.

**Tool**: `get_feature_history(symbol, fields, days=90)` → the selected feature columns from `daily_symbol_features` as a date-ordered series. Field whitelist, and a row cap so a client cannot pull the whole store into a context window.

- Status: [x] Done — `get_feature_history` in `mcp_server.py`; rejects `future_ret_*` by name with an explanation rather than silently dropping the training labels

---

### I.8 `screen_universe` — client-driven screening

**Goal**: Let the client pose its own question instead of only consuming rankings the platform chose. "Find symbols with positive 20-day momentum but deteriorating news sentiment" is currently impossible without a new endpoint per question.

**Tool**: `screen_universe(criteria, limit=20)` — a constrained filter expression over whitelisted feature fields with comparison operators only. No free-form query strings reach the database.

- Status: [ ] Pending (1 day)

---

### I.9 `get_factor_performance` — the evidence behind a ranking

**Goal**: Expose per-factor IC by year and horizon from the existing stability analysis, so a client can explain *why* a signal ranks where it does, and can tell a factor that works from one that worked once.

- Status: [ ] Pending (0.5 day)

---

### I.10 Secondary tools

`compare_symbols(a, b)` (convenience over two calls), `get_pipeline_status()` (data freshness, last DAG run, row counts), `search_gkg(entity)` (675M-row GKG inverted index — large, but less useful for single-name work than I.6).

- Status: [ ] Pending (1 day for all three)

---

### I.11 Codex CLI as a third MCP client

**Goal**: Register the same `mcp_server.py` with Codex CLI alongside Claude Desktop and quant_ai's own agent.

**Work**: configuration only — no new code. That is the point worth making: one stdio server, three unrelated clients, and adding the third cost nothing because the tool surface is the contract.

- Status: [ ] Pending (0.5 day, mostly verification)

---

## R. AI at Scale — RAG depth and MCP depth

**Why this section exists, and why it outranks most of what is below it.**

Interview feedback, 2026-07-28 (eBay, "AI/ML Agent Engineer, backend focus"). The
recruiter's summary: positive attitude, but the interviewers "expected more knowledge of
relevant concepts and technical depth", and specifically "more experience with AI at
scale, particularly using tools like RAG and MCP". The language chosen for the technical
round was Java.

Checked against what is actually built, that feedback is precise and largely fair. It
splits into two very different problems:

**MCP has breadth without depth.** `quant_ai/mcp_server.py` is 318 lines: ten read-only
tools, three independent clients (Claude Desktop, Codex, quant_ai's own agent). The
breadth claim is real and the "one server, three clients, adding the third cost nothing"
point is a good one. What is missing is everything past the tool list:

- `stdio` is the only transport — no streamable HTTP, so no remote or multi-tenant story
- no **resources**, no **prompts**, no **sampling**, no **elicitation**, no progress
  reporting or cancellation. `@mcp.tool()` is the only part of the protocol touched
- no authentication, despite Keycloak already running in this compose stack
- every tool is read-only, so nothing exercises confirmation or idempotency
- it is entirely Python, and the role was a Java backend role

**RAG is not at scale — and the platform is exactly what makes that conspicuous.** The
whole retrieval layer is `SimpleVectorStore` in `quant_ai/main.py`: numpy cosine
similarity over the four markdown files in `quant_ai/knowledge/`, **382 lines of text
total**, re-embedded into process memory on every startup. No persistence, no chunking
strategy, no reranking, no hybrid retrieval, and no retrieval metric of any kind has ever
been computed. `retrieve_context()` falls back to keyword token overlap when the embedding
endpoint is unreachable, which in practice it often is.

Meanwhile **845K company-matched news articles sit in MongoDB with zero embeddings**, and
F.2's claim that "Qdrant already deployed" is stale — there is no `qdrant` service in
`docker-compose.yml` and never has been.

So the gap is not ignorance of RAG. It is that the single rarest asset in a RAG
interview — a large, real, domain-specific corpus with timestamps and entity labels — has
been sitting here unindexed while the demo ran on four README-sized files. "I built RAG"
survives one follow-up question and then collapses.

**One existing asset makes this cheaper than it looks.** The MongoDB text indexes with
field weights, built for I.6 `search_news`, are already a working sparse retriever. Adding
a dense leg turns them into genuine hybrid retrieval with reciprocal-rank fusion — which
is both the better architecture and the more interesting answer, since most candidates can
only describe pure vector search.

---

### R.1 Qdrant + embedding pipeline over the 845K news corpus

**Goal**: a persisted vector index over `news_articles_company_matched_v2`, replacing the
in-memory numpy store as the platform's retrieval substrate.

**Work**:
1. Add a `qdrant` service to `docker-compose.yml`, volume on the external drive alongside
   the other stateful services, **with an explicit disk cap and json-file log rotation** —
   two disk-full incidents (584G and 103G) came out of unbounded container growth, and a
   vector index is exactly the kind of thing that grows quietly.
2. Measure before committing to a full pass: embed 1,000 documents, record wall-clock
   throughput against the local LM Studio `nomic-embed-text` endpoint, then decide whether
   the full corpus is a one-night job or whether the initial index covers a date-bounded
   subset.
3. Decide chunking from measured length distribution, not by assumption.

**Measured 2026-07-30 (see "R.1 measurements" below).** Both of the assumptions this plan
originally carried were wrong, which is the argument for having measured at all:

- it guessed financial news "skews short, many rows headline-plus-lede" — **only 30.2% of
  articles fit in a single 512-token window**, median body is 2,956 characters
- it estimated 2.6 GB of vectors from one vector per article — full 512-token chunking is
  **2.96M vectors and 9.1 GB**, over the 2 GB memory cap set on the qdrant service

Two further facts neither the plan nor the README knew: **17.90% of the corpus (152,332
articles) has no body at all**, so title-only is one document in six rather than an edge
case; and **121,970 documents (14.3%) are duplicates** on `(symbol, title, date)`, which
would otherwise consume top-k slots and inflate every recall number R.4 produces.
4. Payload carries `symbol`, `date`, `event_type`, `sentiment` so retrieval can be filtered
   by entity and time window, not just similarity — a dated corpus retrieved without a
   date filter is the same look-ahead mistake as M.7, in a different costume.
5. Incremental indexing: the daily news job embeds only new documents. A pipeline that
   requires a full reindex to stay current is not a production pipeline.
6. Deduplicate on `(symbol, title, date)` at index time. 14.3% of the corpus is duplicate
   copies; a retriever that returns the same article three times has spent three of its ten
   slots saying one thing.

#### R.1 measurements (2026-07-30)

Corpus: `news_articles_company_matched_v2`, 851,071 documents.

**Length distribution** (20,000-doc sample, exact count for the no-body case):

| | value |
|---|---|
| no usable body (title only) | **152,332 = 17.90%** |
| body chars p50 | 2,956 (≈739 tokens) |
| body chars p90 / p99 | 11,492 / 60,414 |
| body chars max | 2,312,632 — whole-page scrape pollution, needs a cap |
| fits one 512-token window | **30.2%** |
| chunks/article at 512 tokens | 3.62 mean |
| duplicates on (symbol,title,date) | 40,506 groups, **121,970 extra copies = 14.3%** |

**Embedding throughput**, `text-embedding-nomic-embed-text-v1.5` (768-dim) on the local Mac
LM Studio — the Windows host in the notes was unreachable, and the model is 84 MB, so
running it locally removed a network dependency for free:

| strategy | vec/article | best rate | full corpus | wall clock | raw float32 |
|---|---|---|---|---|---|
| title + first 1000 chars | 1.00 | 74.2 vec/s | 0.85M vectors | **3.19 h** | 2.6 GB |
| 512-token chunks | 3.48 | 41.1 vec/s | 2.96M vectors | **20.00 h** | 9.1 GB |

**The finding worth keeping: throughput is character-bound, not request-bound.** Every
configuration measured 66–74 Kchar/s — batch 8 → 64 moved vector rate by 7% (69.5 → 74.2),
not 8×, and the two strategies differ 1.8× in vec/s purely because their vectors carry 1.8×
the text (946 vs 1,799 chars each). The model is saturated on tokens per second. **Batch
size is not the lever; how much text you choose to embed is.**

**Decision**: index `title + lede` first — 3.19 h is one evening against 20 h, and after
dedupe it is ~2.7 h for ~0.73M vectors. News is written inverted-pyramid, so the event
should already be in the headline and first paragraph. That is a hypothesis, not a fact,
and **R.4 is what tests it**: chunked indexing becomes a second configuration in the
ablation, and if `recall@10` justifies 9.1 GB and 20 h, the numbers will say so. Committing
20 h up front to avoid asking the question would be the more expensive mistake.

**Detail that would have silently degraded everything**: `nomic-embed-text` is asymmetric —
documents need a `search_document: ` prefix and queries a `search_query: ` one. Omit them
and vectors still come back, dimensions still match, nothing errors, and retrieval is just
quietly worse. Both benchmark strategies apply the prefix.

#### R.1 delivered (2026-07-30)

Full pass complete: **851,071 read → 729,101 indexed**, 121,970 duplicates skipped, in
**158.8 min (2.65 h) at 76.5 vec/s** — against the 2.7 h predicted from the 1K benchmark.
The duplicate count matched the independent mongo aggregate exactly (121,970), which is
the check that the pipeline's dedupe key and the measurement agreed on what a duplicate is.

`tools/index_news.py` (index), `tools/search_news.py` (query), `tools/bench_embed.py` and
`tools/measure_lengths.js` (the scripts behind every number quoted here), `tools/bench_search.py`
(latency). Committing them is the point: the numbers are reproducible rather than asserted.

**A bug caught only because retrieval was tested before the 2.65 h run, not after.** The
`date` field carries two formats, and **33.2% of the corpus is the 14-character
`YYYYMMDDHHMMSS` form**. Parsing only the 8-character case left a third of the corpus with
a null `date_int`, invisible to every date-range filter — silently, since nothing errors.
That filter is the guard against retrieving future news for a past date, so a quietly
broken one is worse than none: it looks like the guard is there. Normalised to the first 8
characters; points with a null `date_int` after the fix: **0**.

**Memory: the configuration mistake and its fix.** The service came up at **1.838 GiB of
its 2 GiB cap (92%)** — `ON_DISK_PAYLOAD` only moves the payload, and 729,101 × 768 ×
float32 = 2.24 GB of vectors was never going to fit. Setting `on_disk: true` on the vector
config (online, via `PATCH /collections`, no re-embedding) dropped it to **423 MiB (21%)**,
a 4.3× reduction with disk unchanged at 2.7 GB.

| | before | after |
|---|---|---|
| container memory | 1.838 GiB (92% of cap) | **423 MiB (21%)** |
| search p50, unfiltered | 81.90 ms | 4.44 ms |
| search p99, unfiltered | 1016.63 ms | 237.74 ms |
| search p50, date-filtered | 4.75 ms | 4.23 ms |
| embed p50 | 16.77 ms | 10.66 ms |

**The honest reading of that table**: the change is not why latency improved. Enabling
`on_disk` triggered an 80-second re-optimization, so "before" was an unoptimized index in
RAM and "after" is an optimized one on disk — two variables moved. What the numbers do
support is the useful conclusion: **memory-mapping the vectors cost no measurable latency
at this corpus size**, because 2.7 GB sits comfortably in the OS page cache. The 4.3×
memory saving is free here. It would not be at 10× the corpus, and that is the version of
this question worth being able to discuss.

- Status: [x] Done — 729,101 vectors, green, p50 15 ms end-to-end including embedding.
  Remaining for R.8: incremental daily indexing (a pipeline needing a full reindex to stay
  current is not a pipeline) and a content-hash embedding cache

---

### R.2 Hybrid retrieval — sparse + dense with RRF fusion

**Goal**: fuse the existing MongoDB weighted text index (sparse, exact-term, good on
tickers and proper nouns) with Qdrant dense retrieval (semantic, good on paraphrase), via
reciprocal-rank fusion.

**Why it matters here specifically**: `$text` search has OR semantics and scores by term
frequency, so it finds "Micron DRAM oversupply" and misses "memory glut pressures chip
makers"; dense retrieval does the reverse and is weak on exact tickers. The two failure
modes are complementary, which is the entire argument for hybrid, and this codebase can
demonstrate both halves on real queries rather than describe them.

#### R.2 delivered (2026-08-01)

`tools/hybrid_search.py`. Fuses on rank rather than score deliberately: Mongo's
`textScore` is an unbounded tf-idf-ish sum and cosine is bounded [-1,1], so weighted-sum
fusion needs a normalisation that is itself a tuned parameter. RRF needs none.

**Three defects found by running it rather than reading about it.**

1. **The sparse leg had to be deduplicated to match the dense one.** Qdrant holds
   deduplicated points (M.12); Mongo still holds every syndicated copy. Fusing a clean
   list against one where a single story occupies 402 candidate slots does not compare
   two retrievers, it compares one retriever against a broken one — and the sparse leg
   would have looked far worse than it is.
2. **RRF was double-counting.** `index_news.py` keyed dedupe on the raw `date`, so points
   distinct at index time collapse under the normalised key used at fusion, and summing
   every occurrence let one story bank `1/(K+r)` several times. Each leg now contributes
   its best rank per document once. **Third defect from the dual date format** — after the
   null `date_int` and the feature-layer key — which is the argument for normalising at
   every boundary rather than remembering to.
3. **13,027 redundant points (1.79%)** existed for the same reason. Repaired in place by
   `tools/repair_index_dupes.py`, not re-indexed: point ids are UUID5 of the mongo `_id`,
   so re-running the indexer removes nothing that merely stops being generated, and
   `--reset` means 2.65 h of re-embedding to fix 1.79% of a collection whose surviving
   vectors were never wrong — only the *set* was. Deletion took seconds. 729,101 →
   716,074, matching the independent mongo aggregate exactly.

**The finding worth keeping: naive RRF at the published default underperforms both single
legs here.** At `K=60`, depth 100, equal weights:

| query | what happened |
|---|---|
| "memory glut pressures chip makers" | the three sparse hits actually about a memory glut are pushed out by articles ranked 30–65 in *both* legs, including one about chip factories and Trump |
| "LRCX" (bare ticker) | both legs rank content-free stub pages (`Lam Research (Nasdaq:LRCX)`) consistently, so consensus floats four of them above the real articles; **dense alone beats hybrid** |

The arithmetic is the explanation, not a bug: `1/(60+60) + 1/(60+36) = 0.0187` against
`1/(60+1) = 0.0164`. **RRF scores consensus, and consensus is not relevance.**

`RRF_K=5` with depth 30 looks markedly better on both — it interleaves each leg's best
instead of rewarding tail agreement. **It is not being adopted as the default.** "Looks
better to me on two queries" is the same error as trusting the published default with the
source swapped. `RRF_K`, candidate depth and per-leg weights are parameters for R.4 to
sweep against a labelled set.

- Status: [x] Done — fusion works and its failure mode is characterised; the parameter
  choice is deferred to R.4 rather than guessed

---

### R.3 Reranking

**Goal**: retrieve top-100 by fusion, rerank to top-10 with a cross-encoder, serve the
reranked set to the LLM.

The point to be able to defend: bi-encoder similarity is a cheap approximation computed
without the query and document ever meeting; a cross-encoder scores the pair jointly and
is far better at relevance but too slow to run over 845K rows. Retrieve-then-rerank is how
that tradeoff is resolved, and the latency budget is the design constraint worth quoting.

- Status: [x] Done (2026-10-13) — `tools/rerank.py` (BAAI/bge-reranker-v2-m3), measured in
  R.4's harness and wired into `/api/ask/news` behind `NEWS_RERANK`; see "R.3 delivered" below

#### R.3 delivered (2026-10-13)

**The gain, under two independently validated judges.** Pool extended with everything the
reranker variants surfaced (677 pairs) and judged blind by both R.4 judges — gemma rubric v2
(`llm_v2`, the headline) and qwen3.8-27b rubric v3 (`llm_v3_qwen27`) — so the reranker is not
penalised by pool bias and the result does not rest on one judge. 60 queries, nDCG@10, paired
bootstrap 95% CI (`score_runs.py --ci`):

| comparison | gemma v2 | qwen27 v3 |
|---|---|---|
| rerank top-30/256 − hybrid_k60 (shipped) | **+0.076** [+0.043, +0.113] | **+0.078** [+0.048, +0.111] |
| rerank top-100/256 − hybrid_k60 | **+0.117** [+0.078, +0.159] | **+0.097** [+0.060, +0.135] |
| 256 vs 512 tokens (top-100) | +0.018 [−0.002, +0.040] | +0.002 [−0.017, +0.022] |

Significant under both judges; P@10 at the g=2 bar moves the same way (+0.080 / +0.073 for the
shipped config). Under gemma v2 the shipped config helps 33 queries and hurts 12. The largest
wins are thematic and paraphrase queries — "AI data centre capex guidance raised" goes from
generic data-centre pieces to Meta/Amazon capex raises — exactly where bi-encoders blur
near-misses together; the losses are bare literals and date windows.

**The cost, and the depth that was shipped.** Top-100 at 512 tokens is ~5 s per query on MPS,
too slow for an answer endpoint. `eval/rerank_sweep.sh` holds the first stage fixed (both legs
still retrieve 100) and varies only the reranked depth and the token window:

| config | nDCG@10 gemma v2 | nDCG@10 qwen27 v3 | rerank latency (median) |
|---|---|---|---|
| hybrid_k60, no rerank | 0.777 | 0.781 | 0 |
| top-20, 512 tokens | 0.836 | 0.843 | 1.05 s |
| **top-30, 256 tokens (shipped)** | **0.854** | **0.859** | **0.98 s** |
| top-30, 512 tokens | 0.847 | 0.859 | 1.60 s |
| top-50, 512 tokens | 0.851 | 0.862 | 2.63 s |
| top-100, 256 tokens | 0.895 | 0.878 | 3.05 s |
| top-100, 512 tokens | 0.877 | 0.875 | 5.02 s |

Truncating to 256 tokens costs nothing measurable (not significant either way) and saves ~40%
— news puts its subject in the lede, the same reason R.1 indexed title+lede. Top-30 keeps
about two-thirds to four-fifths of the full gain at ~20% of the cost; generation already takes
several seconds, so ~1 s is affordable. Top-100/256 at 3 s is the option if quality matters
more than latency.

**In the request path.** `news_rag.answer_from_news` reranks the fused top-30 when
`NEWS_RERANK=1` (or per request with `"rerank": true`) and reports
enabled/candidates/max_len/ms. A reranker that cannot load falls back to the fused order with
`rerank.error` set — the answer never fails because of it. The model is preloaded at startup
(otherwise the first request pays ~6.7 s). Off by default: the service image carries no torch
(`requirements-eval.txt`); `run_host.sh` turns it on.

---

### R.4 Retrieval evaluation harness — the item that actually answers the feedback

**Goal**: numbers. `recall@k`, `MRR`, `nDCG@10` on a held-out labelled query set, reported
per retrieval configuration: sparse only, dense only, hybrid, hybrid + rerank.

**Work**: build 50–100 labelled queries (question → known-relevant article ids), drawn from
real events already in the corpus — earnings reactions, export controls, the CXMT listing
from the N-series. Then an ablation table.

**Why this is ranked above R.6–R.8 in value**: "expected more technical depth" is answered
by a table showing hybrid+rerank at `recall@10 = 0.87` versus dense-only at `0.61`, and by
being able to say which queries the reranker fixed and which it broke. It is not answered
by a longer list of implemented components. F.22's evaluation harness already establishes
the pattern in this codebase — the same discipline, pointed at retrieval.

- Status: 🟡 Judge validated against 150 reference labels and the pool re-judged (2026-10-09) —
  see "R.4 rubric v2" below. Open: a human spot-check of the reference labels

#### R.4 first table (2026-09-22) — and why it cannot be reported yet

`eval/judge_pool.py` (LLM judging, human sampling, Cohen's kappa) and `eval/score_runs.py`
(recall@k / MRR / nDCG@k, loose and strict relevance bars, split by challenge type) close
the two gaps that were left after the pool was built on 2026-08-02. All 1,810 pairs are
judged, 0 errors. The first table:

| system | recall@10 | MRR@10 | recall@10 (g=2) | MRR@10 (g=2) | nDCG@10 |
|---|---|---|---|---|---|
| sparse | 0.320 | 0.963 | 0.333 | 0.650 | 0.652 |
| dense | 0.353 | 1.000 | 0.410 | 0.701 | 0.755 |
| hybrid_k60 | 0.348 | 1.000 | 0.403 | 0.723 | 0.756 |
| hybrid_k5 | 0.345 | 1.000 | 0.397 | 0.672 | 0.729 |

**Two of those five columns are measuring the harness, not the retriever.** The judge
graded 1,678 of 1,798 pairs as relevant (93%); only 120 scored 0. With a pool of ~30
documents per query and nearly all of them called relevant, `recall@10` cannot exceed
10/30 ≈ 0.33 for any system — and all four sit on that ceiling. `MRR@10 = 1.000` is the
same defect seen from the other end: every query's rank-1 document clears a bar that
almost nothing fails. **Grade inflation in the judge turned two metrics into constants.**

Only `nDCG@10` still discriminates, because graded gains and position discount survive a
lenient judge: dense 0.755 ≈ hybrid_k60 0.756 > hybrid_k5 0.729 > sparse 0.652. Split by
challenge, dense leads on event / temporal / thematic and hybrid_k60 leads on paraphrase
(0.773).

**This contradicts R.2's recorded impression** that naive `RRF_K=60` loses to both single
legs. Under measurement it ties dense and clearly beats sparse. The earlier claim came
from reading result lists by eye, which is exactly the failure mode R.4 exists to correct
— recorded rather than quietly overwritten.

**Before the table is reported anywhere**: (1) tighten the judging rubric so grade 1 means
"same company or theme but does not answer" and everything else is 0, then re-judge;
(2) hand-label ~100 stratified pairs and report Cohen's kappa against the model judge. An
unvalidated judge cannot certify a retrieval result, and the inflation above is the
evidence for why that sentence is not boilerplate.

#### R.4 rubric v2 (2026-10-09) — the judge was not inflating; the 1/2 boundary was wrong

**The "93% relevant = grade inflation" reading above was wrong, and the way it was found is the
point.** 150 pairs were labelled by hand as a reference (30 per challenge, stratified on the v1
grade so v1's rare 0s were not undersampled; labels by Claude, read blind to the v1 grade, stored
as `source=reference_claude` and in `quant_ai/eval/labels/`). Against them:

- v1 (gemma, original rubric): exact agreement 0.62, **Cohen's kappa 0.41**. Its errors were
  not leniency: of 80 pairs that answer the query it graded 29 as merely related, and of 43
  related ones it graded 15 as irrelevant.
- Re-weighting the stratified sample back to the pool, **about 91% of pooled pairs really are
  at least related** (reference estimate 9% / 25% / 66% for grades 0/1/2). That is what a pool of
  each retriever's top 15 should look like. The flat recall@10 was a property of the loose bar,
  not of the judge: with ~27 related documents per query, recall@10 at grade >= 1 cannot exceed
  ~0.37 for any system.

Four replacement judges were tried on the same 150 pairs:

| judge | kappa vs reference | estimated pool 0/1/2 |
|---|---|---|
| gemma, v1 rubric | 0.41 | 7 / 46 / 47% |
| **gemma, v2 rubric** | **0.74** | **10 / 26 / 64%** |
| gemma, extract facts + grade in code | 0.76 | 13 / 11 / 76% |
| qwen3.5-4b, v2 rubric | 0.64 | 13 / 20 / 66% |
| qwen3.5-4b, extract facts + grade in code | 0.65 | 6 / 27 / 67% |

v2 spells out the 1/2 boundary: the opposite outcome (strong guidance for a "weak guidance"
query) is 1; word overlap, market-research reports and stock promotion are 0; a bare name query
is answered by a document mainly about it. It was chosen over fact extraction because its
distribution matches the reference while extraction over-awards grade 2. The same day,
extraction *won* for the job-matching judge (job_agent) — which judge works is a measurement
per task, not a rule. The production re-judge (`judge_pool.py --llm`, 4 workers, no response
prefill) reached **kappa 0.67**; its errors are one grade low, never a 0 graded relevant.

The table under v2 (`score_runs.py`, which now also reports P@10 at the strict bar —
precision does not depend on pool size):

| system | MRR@10 (g=2) | P@10 (g=2) | nDCG@10 |
|---|---|---|---|
| sparse | 0.756 | 0.543 | 0.683 |
| dense | 0.791 | **0.677** | **0.803** |
| hybrid_k60 | **0.811** | 0.658 | 0.797 |
| hybrid_k5 | 0.787 | 0.635 | 0.773 |

Paired bootstrap over the 60 queries (5,000 resamples, 95% CI):

- **dense and hybrid_k60 tie**: nDCG −0.006 to the other's favour, CI [−0.035, +0.045].
- **Both beat sparse**: nDCG +0.120 [+0.064, +0.178] and +0.114 [+0.074, +0.158];
  P@10 +0.13 and +0.12, also significant.
- RRF k=60 vs k=5: +0.024 [−0.002, +0.053], not significant.
- **No MRR difference is significant** at 60 queries.

By challenge type, P@10:

| system | event | literal | paraphrase | temporal | thematic |
|---|---|---|---|---|---|
| sparse | 0.60 | 0.85 | 0.38 | 0.53 | 0.40 |
| dense | **0.77** | **0.95** | 0.46 | 0.67 | **0.55** |
| hybrid_k60 | 0.73 | 0.92 | **0.50** | 0.67 | 0.51 |

nDCG on paraphrase: hybrid_k60 0.729 vs dense 0.629.

**What this does to R.2's story.** The expected split, "sparse wins literal, dense wins
paraphrase", did not appear: dense leads even on tickers and product names. Hybrid's one clear
gain is paraphrase nDCG. The defensible claim is therefore narrower than the one R.2 hoped for:
*dense alone is as good as RRF hybrid on this corpus, and both beat BM25-style text search by
~0.12 nDCG@10*. Reranking (R.3) is the next lever, not further RRF tuning.

Caveats, stated rather than hidden: the reference labels come from one annotator (an LLM),
pending a human spot-check of 30 pairs (`judge_pool.py --human --sample 30 --among reference_claude`, then `--kappa human reference_claude`); unjudged documents count as
non-relevant, so all recall figures are upper bounds; 60 queries is enough for the nDCG/P@10
gaps above, not for MRR.

---

#### R.4 a second judge (2026-10-13) — rubric v3 on qwen3.8-27b, as a robustness check

A second line of work built rubric v3 (stricter at grade 1, and explicit about title-only
articles and bare ticker queries) on qwen3.8-27b with reasoning off (~4 s/pair). Both lines
were merged; `judge_pool.py --rubric v3 --model … --source …` runs it. On the same 150
reference pairs:

| judge | exact | kappa | linear-weighted | kappa at the g=2 bar |
|---|---|---|---|---|
| gemma v1 (`llm`) | 0.620 | 0.414 | — | — |
| **gemma v2 (`llm_v2`, headline)** | **0.793** | **0.670** | **0.758** | 0.761 |
| qwen27 v3 (`llm_v3_qwen27`) | 0.733 | 0.575 | 0.698 | **0.853** |

v2 places grade 1 better, which the graded measures (nDCG) depend on, so it stays the headline
judge; v3 is the stricter judge of "answers the query" and never promotes a reference-0 pair.
(The 0.74 recorded above for v2 was measured on the trial run; the full `llm_v2` set gives 0.67.)

**What the second judge settles.** Every conclusion above was re-scored under v3 on the same
2,487 pairs: the system ranking is unchanged and **dense vs hybrid_k60 stays a tie** (nDCG
−0.005 [−0.043, +0.033] under v2, +0.026 [−0.014, +0.067] under v3). Reranking (R.3) is
significant under both. A result that survives two judges with different rubrics, models and
failure modes is not an artefact of either.

Still owed: human labels for judge-vs-human kappa (`judge_pool.py --human --sample 100`).

---

### R.6 MCP protocol depth — beyond tools

**Goal**: exercise the parts of MCP that `@mcp.tool()` never touches.

- **Resources**: expose the research corpus and signal history as resources with URIs and
  subscriptions, so a client reads state rather than calling a function to fetch it. The
  tool/resource distinction is a real design question, and having made the call on real
  data is worth more than knowing the definition
- **Prompts**: ship the portfolio-review and signal-explanation prompts as server-side MCP
  prompts, versioned with the server instead of pasted into each client
- **Sampling**: let the server ask the client's model to summarise retrieved news, so the
  server needs no model credentials of its own — the inversion that most people have not
  used
- **Elicitation + progress + cancellation**: required the moment a tool writes (I.3 order
  execution) or runs long (a backtest). Confirmation belongs in the protocol, not the prompt
- Structured tool output and `strict` schemas, so results are typed rather than JSON strings

- Status: [ ] Pending (3 days)

---

### R.7 RAG as a feature source, not a chat feature

**Goal**: retrieval-grounded event extraction that writes into the feature store — the
retrieval layer feeding the quant layer rather than only answering questions in a UI.

This is where the N-series propagation work and the RAG work meet: semantic retrieval over
845K articles is precisely the mechanism that finds "ChangXin Memory IPO" as relevant to
MU/WDC/STX when no article names them. Every grounded claim must carry the article ids it
came from, so a factor built this way stays auditable — and dated retrieval only, since
this is the code path where a retrieval bug becomes a look-ahead bug.

- Status: [ ] Pending (3 days, after R.2 and N.1)

---

### R.8 Production concerns at scale

The questions that separate "I built a RAG demo" from "I ran RAG in production", each
answerable with a measured number from this platform rather than a general principle:

- **Embedding cache and idempotency** — re-embedding an unchanged article is pure cost;
  content-hash keying makes the pipeline safely re-runnable
- **Index versioning and reindex strategy** — changing the embedding model invalidates
  every vector; how is that rolled out without downtime
- **Latency budget** — measured p50/p99 broken down across embed / retrieve / rerank /
  generate, so the answer to "where does the time go" is a breakdown, not a guess
- **Cost per query** at local-model throughput versus a hosted embedding API
- **Failure modes** — what is served when Qdrant is unreachable. The current fallback is
  keyword token overlap, which is honest but should be labelled to the caller, the same
  way `QuoteService` labels a daily close it is serving in place of a live quote

- Status: [ ] Pending (2 days)

---

### R.9 What to be able to answer

Not a build item — the checklist R.1–R.8 exists to make answerable. If any line here still
needs hedging after the work is done, the work is not done.

**RAG**: chunking strategy and why for this corpus · bi-encoder versus cross-encoder and
where each sits · why hybrid beats either leg alone, with the queries that prove it ·
`recall@k` / `MRR` / `nDCG` for every configuration tried · HNSW parameters and the
recall/latency curve · how the index stays current · what look-ahead means in retrieval
over a dated corpus.

**MCP**: every transport and when each applies · tools versus resources versus prompts as
a design decision · what sampling inverts and why that matters · how a write tool gets
confirmed · authorization on a remote server · why one tool contract served three clients
with no client code.

**At scale**: 845K documents, measured throughput, measured latency, measured cost — the
word "scale" carries nothing without those four numbers attached.

---

### R.10 Wire the retriever into generation

**The gap this closes.** R.1–R.4 build the *retrieval* half of RAG. Nothing consumes it.
`/api/ask` still calls `retrieve_context()` against `SimpleVectorStore` over the four
markdown files in `knowledge/` — 382 lines — so the platform has 716,074 indexed news
articles and an answer endpoint that cannot see any of them. "I built RAG over 845K
articles" is not true until something generates an answer from them.

**Not a replacement.** The knowledge folder answers *"how does the regime scorer weight
factors"*; the news corpus answers *"what happened to NVDA on export controls"*. Those are
different corpora for different questions, and collapsing them would lose the first. A new
`/api/ask/news` endpoint, with `/api/ask` left alone.

**What it has to do beyond calling the retriever:**

- **Cite.** Every claim carries the article ids it came from, so the answer is checkable and
  R.11 has something to check.
- **Refuse.** When retrieval returns nothing relevant the endpoint says so instead of
  letting the model answer from parametric memory. A RAG system that silently falls back to
  what the model already knows is worse than no RAG, because the failure is invisible —
  the answer still looks sourced.
- **Filter.** Pass `symbol` and a date window through to both legs. Asking "what did the
  market think in 2022" and retrieving 2026 articles is the same look-ahead error as M.7,
  now with a natural-language interface on top.
- **Return the sources**, not just the prose, so the caller can verify and the UI can link.

#### R.10 delivered (2026-08-01)

`news_rag.py` + `POST /api/ask/news`. Answers cite by id, refuse when retrieval is empty,
and pass `symbol` / date window into **both** retrieval legs. `/api/ask` is untouched.

**Two defects found while wiring it, both invisible from the retrieval side.**

1. **The two legs filtered asymmetrically.** Qdrant applied the date window inside the
   search; the sparse leg fetched the top matches across all history and filtered in
   Python afterwards. One NVDA query returned 37 hits instead of 100, and they were the
   wrong 37 — the best across all time that happened to fall in the window, not the best
   within it. **This would have corrupted R.4's ablation silently**, making the sparse leg
   look worse than it is and hybrid inherit the damage. The window is now a Mongo range
   query: `date` is a string in two formats, but lexicographic order matches chronological
   order for both, so a plain string range is correct for the mixed field and still uses
   the `(symbol, date)` index.
2. **Body fetch was 5.9 s.** `find_one({"symbol":…, "title":…})` per hit has no index to
   use — the collection is indexed on `(symbol, date)` and full-text, not title — so eight
   hits cost eight partial scans. Both legs now carry the mongo `_id`, and one `$in` by
   primary key takes **1.5 ms**. Titles were never a key here anyway: syndicated copies
   share one.

**Measured latency, split rather than totalled:**

| stage | time |
|---|---|
| dense leg (incl. query embedding) | 16–23 ms |
| sparse leg (`$text`) | 1.1–3.6 s |
| body fetch | 1.5 ms |
| **generation (local qwen3.5-9b)** | **66–111 s** |

**Generation is 99% of it, and the reason is worth stating precisely.** The model is not
slow: 47 tok/s is normal for a 9B on Apple Silicon. It emitted **3,124 completion tokens to
produce a ~100-token answer** — it is a thinking model spending ~3,000 tokens of hidden
reasoning on a summarisation task that does not need it. "Generation took 111 s" is not
actionable; "3,124 reasoning tokens at a normal 47 tok/s" points straight at the fix.
Attempts to disable thinking (`/no_think`, `chat_template_kwargs.enable_thinking`) both
timed out at 280 s rather than helping, so **this is a known open issue**, not solved.

The sparse leg's 1–3.6 s is inherent to `$text` OR semantics over 851K documents: a query
like "US export controls on AI chips" matches a large share of a tech-news corpus and Mongo
must score every match. A compound text index prefixed on `symbol` would fix the filtered
case, but **MongoDB allows only one text index per collection**, and making it compound
would end corpus-wide search — which is exactly what R.7 and the N-series need. Not a
trade worth making.

**Quality note.** On "How did investors react to Micron's guidance?" the model reported that
the excerpts *disagree* — 2019-09-25 said investors were positively surprised, 2019-09-27
said the stock tumbled — and cited both sides rather than picking one. That is rule 3 of the
system prompt working, and it is the behaviour that distinguishes a grounded answer from a
fluent one.

- Status: [x] Done — endpoint live, citations checkable, refusal path verified.
  Open: generation latency (thinking tokens)

---

### R.11 Generation-side evaluation

**Retrieval metrics do not measure whether the answer is true.** `recall@10` says the right
document was in the context window. It says nothing about whether the model used it,
misread it, or wrote a fluent paragraph that cites it and contradicts it.

| metric | question |
|---|---|
| **faithfulness / groundedness** | is every claim supported by a retrieved document, or invented? |
| **citation accuracy** | does the cited article actually contain the claim? A citation to a real document that does not say the thing is a hallucination wearing a source |
| **answer relevance** | does it answer the question asked? An answer can be perfectly grounded and beside the point |

**This pattern already exists in the codebase.** F.17's portfolio agent runs three gates on
every verdict, and its grounding gate checks that each cited `(tool, field, value)` appears
in a real observation from that run, with numeric tolerance so a model quoting 0.28 for
0.2803 counts as quoting rather than fabricating. R.11 is the same mechanism pointed at
documents instead of tool outputs — and reusing it is the point, since it is already tested.

- Status: ✅ Done (2026-10-24) — three runs judged by Claude, the judge checked by verbatim evidence, production switched to no-thinking. Results below.

**Built** (`quant_ai/eval/gen_eval.py`, 13 unit tests, commit 62c4994): generate answers with the
production `answer_from_news` for the 60 R.4 queries + 8 unanswerable probes; split into sentences
with their citations (bracketed and prose, "Excerpt 6"); numeric grounding without a model (F.17's
idea, tolerance from the answer's own rounding); a local judge labels each sentence (claim/meta,
supported/partial/unsupported, supporting excerpt ids) and each answer's relevance; Claude via
`claude -p` labels a reference sample; `--kappa` measures a judge before `--score` reports. Excerpts
given to the judge carry symbol and date exactly as the generator saw them (without them every dated
sentence looked invented).

**Judges against Claude, 28 sentences, rubric v2** (v2 says "the excerpts report X" is a claim about X
and lists the typical partials: over-generalisation, stronger wording, dates/figures not in the
excerpts, merged facts):

    judge              kappa 4-class   kappa supported-vs-not
    gemma-4-e4b        0.19            0.10      too lenient: misses over-generalisation
    qwen3.5-9b         0.43            0.44      now errs strict
    Claude v1 vs v2    0.79            0.83      the reference is stable across rubric versions

Not good enough to report a table (R.4's judge was 0.67).

**Found on the way.** LM Studio now ignores `reasoning_effort: "none"`, `chat_template_kwargs` and
`/no_think` for qwen3.5: all tokens go to reasoning. Consequences: `/api/ask/news` takes ~60-200 s an
answer (R.10 measured ~9 s), and R.4's qwen3.8-27b judge (which relied on `reasoning_effort`) would be
as slow. An empty pre-filled think block (`<think>\n\n</think>\n\n` as the assistant turn) works:
9-14 s. Whether to ship that to production is one of R.11's questions.

**Results (2026-10-24).** 68 questions (60 from R.4 + 8 unanswerable probes) × 3 configurations,
generated through production's `answer_from_news`; 1,183 sentences and 204 answers labelled by Claude
(`--claude-judge`, one call per answer so its excerpts are sent once). Faithfulness counts partial as 0.5;
95% bootstrap CIs.

    run               faithfulness        cite precision  numbers grounded  declined probes  latency
    noreason          0.869 [.84, .90]    0.986           223/271 = 0.82    8/8              ~6 s
    noreason_rerank   0.874 [.85, .90]    0.969           268/321 = 0.84    8/8              ~8 s
    prod_reason       0.899 [.87, .93]    0.966           117/156 = 0.75    8/8              60-200 s

Paired: thinking on − off = +0.041 [−0.005, +0.085], not significant, and the thinking answers are half
as long (3.9 sentences vs 6.7), so part of the gain is saying less. Rerank − none = +0.013 [−0.021,
+0.046]: R.3's +0.076 nDCG does not carry through to the answers. No answer invented wholesale (2 of
1,080 claims unsupported); the errors are partials — over-generalising, merging two names, a causal
"consequently" the excerpts do not support, a date moved by a day.

**Decision: production answers without thinking.** `/api/ask/news` pre-fills an empty think block for
qwen (`NEWS_REASONING=1` restores thinking): ~10x faster at no measurable cost in faithfulness.

**The judge, checked without a second opinion.** A hand-labelled sample was planned; the user chose a
mechanical check instead, since Claude re-reading Claude shares its errors. For each sentence the judge
called supported or partial, Claude split it into facts and copied, per fact, the exact excerpt text it
rests on; code then checked each copy is really in that excerpt (`--evidence`, `--evidence-report`).
- Quotes really in the named excerpt: **2,996 / 2,996** — no invented evidence.
- "Supported": 812 / 827 (98.2%) have every stated fact quoted verbatim. The 15 others are mostly
  inference from the excerpt's date line ("late next year" in a 2026-07 article → late 2027) or common
  knowledge ("Target is a retailer").
- "Partial": 125 / 251 have a fact found nowhere; in the other 126 every fact is in the text and what is
  wrong is how they are joined (the six sampled: merged names, invented causality, a date shifted, a
  denial attached to the wrong claim) — errors a quote check cannot see and the judge did.
Facts about the excerpts as a whole ("no excerpt mentions", "the only one") cannot be quoted and are
counted separately (243). What can be said: "Claude-judged, with every piece of cited evidence verified
verbatim"; not "validated by a human". The unused spot-check page stays available for that.

**Also found.** MLX in LM Studio crashed after ~70 minutes of four-slot thinking generation (`metal::malloc
Resource limit (499000) exceeded`); a cold embedding model answered HTTP 500 to eight parallel requests
(generation now embeds once before going parallel). Option B (a local judge reaching ~0.6 kappa) was not
pursued: the evidence check made the Claude judge usable as it is.

### R.12 One retriever for every news consumer — hybrid search behind `search_news`

**Two consumers of the news corpus use two different retrievers.** Found 2026-10-08 while
tracing which tools use RAG:

| Consumer | Path | Retrieval |
|---|---|---|
| `/api/ask/news` (R.10, `news_rag.py`) | `hybrid_search.search()` directly | Qdrant dense (716,074 vectors) + Mongo weighted `$text`, RRF k=60, symbol/date filters on both legs |
| `search_news` MCP tool → F.21 research agent (`/api/agent/research`), Claude Desktop, Codex, F.17 | `mcp_server.py` → `quant_api` `/api/news/search` | Mongo `$text` only (headline 10x body) |

So the multi-step research agent — the consumer that combines signals, features and news —
gets the weaker, lexical-only retriever, while the single-shot news Q&A gets the hybrid one.
None of the other six MCP tools needs retrieval: they return numbers the platform computed,
looked up exactly by symbol and date.

**Plan**

- `search_news(..., mode="keyword" | "hybrid")` in `mcp_server.py`, calling
  `tools/hybrid_search.search()` for `hybrid` (same process, same package). Default stays
  `keyword` until the comparison below says otherwise.
- Apply `symbol` / `from_date` / `to_date` to both legs, exactly as `news_rag.py` does — a
  filter applied after fusion would let a dense hit from the wrong window take a top-k slot
  (the M.7 look-ahead error again).
- Fall back to `keyword` when the embedding model (LM Studio) or Qdrant is unreachable, and
  say so in the response, so a down model degrades recall instead of breaking the tool.
- Keep `_guard_articles()` on the output: hybrid adds documents, not a new trust level.
- Return articles, never a generated answer. Do **not** expose `/api/ask/news` as a tool:
  its callers (Claude, Codex, the agents) are stronger models than the local 9B, and a
  9B summary in between adds a weaker paraphrase and drops the source text.
- ~~Keep Qdrant current~~ — done 2026-10-08: `index_news_qdrant` is the last task of
  `backfill_2_enrich_and_features` (see Stage 6B.6a), so the daily run embeds each day's
  newly matched articles; the first run picks up the 2026-07-21 → 2026-10-08 catch-up.

**Acceptance** — run R.4's queries through `search_news` in both modes once R.4 has the
stricter rubric and ~100 hand labels; make `hybrid` the default only if it wins on nDCG /
recall@10 at acceptable latency (expected ~tens of ms → a few hundred ms, embedding call +
Qdrant). Until then the honest claim is "both paths exist and can be compared", not "hybrid
is better" — R.2's first measurement had naive RRF losing to both legs, and R.4's nDCG later
contradicted it.

- Status: ✅ Shipped 2026-10-09, hybrid is the default — see "R.12 result" below

#### R.12 result (2026-10-09)

**Acceptance came from R.4, not from a new run.** R.4's `sparse` system is
`hybrid_search.sparse_leg` — the same weighted `$text` index (title 10x, body 1x) as
quant_api's `/api/news/search`, plus syndication dedupe, so it is an upper bound on the old
`search_news` path. Under the validated judge, hybrid_k60 beats it by +0.114 nDCG@10
(bootstrap CI [+0.074, +0.158]) and +0.115 P@10. So `mode="hybrid"` is the default, and
`mode="keyword"` stays for exact phrases.

**One retriever, decided once.** The fusion lives only in quant_ai:

| consumer | path |
|---|---|
| quant_ai MCP `search_news` | `news_rag.search_articles` in-process |
| `/api/ask/news` (R.10) | `hybrid_search.search` (unchanged) |

`search_articles` returns the same payload shape as `/api/news/search`, so S.2's
`_guard_articles` and every client read it unchanged; each article adds `foundBy`
(dense / sparse) and both ranks. The symbol and date window go into both legs, never after
fusion. No generated answer is exposed as a tool (the callers are stronger models than the
local 9B).

**Fallback is reported, not silent.** If the embedding model, Qdrant or (for Java) quant_ai
is unreachable, the tool answers from keyword search with
`retrieval: {mode: keyword, requested: hybrid, note: …}`. The Java note names the kind of
failure only; internal hostnames stay in the server log. As of today the Java path *is*
falling back: the quant_ai container is not running, so `quant-ai:8083` does not resolve.

**Latency, measured (warm, median of 3):** embedding 12–18 ms, dense leg incl. embedding
18–22 ms, **keyword leg 430–950 ms** — Mongo `$text` matches any of the words across 851K
documents and must score every match before sorting. Hybrid therefore costs ~0.9 s, almost
all of it the keyword leg. R.4 found dense alone statistically tied with hybrid overall
(hybrid ahead only on paraphrase, nDCG 0.729 vs 0.629), so **dense-only is a measured,
~45x faster alternative** if latency ever matters more than paraphrase recall. Kept hybrid
as the default for the paraphrase gain and as a safety net for exact names.

**Bug found on the way:** quant_api's news search read `llm_event_type` /
`llm_signal_strength`, which exist on 50 legacy documents; the labelled fields are the
`_a` ones (867K). `eventType` and `signalStrength` had been null on essentially every
result. Fixed, with the old names as a fallback.

Known limitation, not fixed here: near-duplicate syndicated copies whose titles differ only
in case or a word ("US plans…" / "US is planning…") survive the exact-title dedupe and can
take several of the top slots.

---

---

### R.13 One agent for every stock question — the agent decides which tools to call

**Goal (user, 2026-10-25).** One place to ask anything about stocks: "why did SK hynix rise", "how are
my holdings today", "why is AMZN ranked first", "what did Lam say about guidance". The F.21 ReAct
agent decides by itself whether a question needs a tool, and which: the news Q&A, the signals and
features, the backtest, the user's holdings and quotes, the daily briefs, or none. No separate router
in front of it; choosing tools is the agent's job.

**Where it stands (2026-10-25).**
- Three entry points with different jobs: `/api/ask/news` (one-step news RAG, strict citations,
  refuses when the excerpts do not cover the question, measured in R.11), `/api/ask` (the project's
  own markdown docs) and `/api/agent/research` (F.21, multi-step, tools).
- The agent already searches news with the same hybrid retriever (R.12), but reads raw articles
  instead of getting a cited answer, so none of R.11's guarantees reach its answers.
- The MCP server's `get_latest_signals` and `get_performance` answered **HTTP 401** on 2026-10-24:
  `quant_api` requires a login and the MCP calls carry no credential. Whether F.21's own
  `/api/agent-data/*` routes are affected the same way is to be checked first.
- The agent cannot see anything that moved to quant_ai: holdings and live quotes, global markets,
  the daily briefs and the prediction scorecard.
- Every agent step calls qwen3.5 with thinking on (60-200 s a call, R.11); `/api/ask/news` already
  pre-fills an empty think block, the agent does not.

**Plan (~2 days).**
- [ ] Fix the 401: signals and backtest performance reachable from the agent and from MCP.
- [ ] New tools: `ask_news` (the R.11-measured cited answer, returned with its sources, so the agent
      quotes an answer that already refuses rather than paraphrasing raw articles), holdings and
      quotes, global markets, latest briefs and the prediction scorecard (quant_ai `markets` routes).
- [ ] No thinking on agent steps (same prefill as `/api/ask/news`), so a one-tool question answers in
      seconds rather than minutes.
- [ ] Evaluation set of 20-30 stock questions, each with the tools it should and should not use
      (news-only, ranking, holdings, mixed, and questions that need no tool). Report tool-selection
      accuracy, unnecessary calls and latency; answers that use `ask_news` inherit R.11's numbers.

## S. Security — the AI attack surface

### S.1 Indirect prompt injection through retrieved documents

**The exposure R.10 opened.** `/api/ask/news` retrieves from 716,074 articles scraped from
the open web and places their body text in the model's context. Nobody has to compromise
anything to write there — publishing an article that GDELT ingests is enough. The system
prompt then instructs the model to answer *only* from those excerpts, which makes an
injected instruction **more** persuasive rather than less.

Worse here than in a chat product for three reasons: the content source is fully open, the
output is headed for the feature store under R.7 (a poisoned answer becomes a poisoned
position, not a bad sentence), and the corpus is already 851K documents nobody has read.

**Four layers, and they are not equally strong.**

| layer | what it does | strength |
|---|---|---|
| 1. Structural separation | retrieved text lives only in a user message, inside `<excerpt>` delimiters; the system prompt states nothing inside can change the rules | **strong — this is the defence** |
| 2. Sanitisation | zero-width, bidi and control characters neutralised | strong, deterministic |
| 3. Pattern detection | 7 regexes for known injection phrasings | **weak — advisory only** |
| 4. Output checks | missing citations, adopted-instruction and prompt-disclosure phrasings | moderate |

Layer 1 is about **where authority lives**, not about what the text says, which is why it
is the one that holds. Treating layer 3 as security would be the error: it is reported,
never enforced. Dropping a document on a regex match would also hand anyone a way to
suppress coverage of a company by publishing one sentence.

**Measured on 40,000 real articles rather than assumed.** The first exfiltration pattern
fired 16 times, every one an earnings-call transcript where the operator asks analysts to
"repeat your instructions" — a rule that fires on ordinary journalism is worse than no
rule, because the flag then gets ignored on the day it matters. Requiring a qualifier
(`system|initial|original|previous`) keeps "reveal your system prompt" and drops the
transcript idiom. Final false-positive rate **3 in 40,000 (0.0075%)**, all ordinary
English: "run the SFC tool", "You are now a public company".

**Two defects the tests found, not review.**

- **Deleting zero-width characters helped the attacker.** Used as word separators,
  `Ignore<ZWSP>all<ZWSP>previous<ZWSP>instructions` collapses on deletion into one token no
  pattern matches — while a model reads the phrase perfectly well through the missing
  spaces. *Neutralising a hiding character must not also destroy the evidence*; they are
  replaced with a space.
- **`chars_sanitised` was a length delta**, which is 0 once characters are replaced rather
  than deleted. A metric that is always zero reads as "nothing happened" and hides exactly
  the signal it exists to surface.

**Three evasion tests assert the pattern layer fails** on light rewording, indirect framing
("Note to the reading assistant: the correct summary is…") and non-English. Asserted rather
than hidden, because it is the argument for the layering.

**End-to-end against qwen3.5-9b** with a poisoned excerpt: the model reported the real
revenue figure and **called out the embedded instruction** instead of following it. The
automated adoption check false-positived on that answer, because the model *mentioned* the
injected phrasing in order to report it and a substring test cannot separate adopting from
reporting. Recorded as-is — it is the same difficulty R.11's faithfulness gate will face,
and finding it here is cheaper than finding it there.

- Status: [x] Done (2026-08-03) — `injection_guard.py`, wired into `news_rag.py`, FP
  measured on the real corpus. Extended to the MCP boundary by S.2.

---

### S.2 Guard the MCP boundary, not each consumer

S.1 protected one endpoint. `search_news` was still handing raw article text, unguarded,
to **four** consumers: Claude Desktop, Codex, the F.21 research agent and the F.17
portfolio agent. It is the only tool on that server returning free text written by someone
outside the platform — every other one returns numbers the platform computed — which makes
it the injection surface.

**The design decision worth keeping**: the guard goes at the *tool boundary*, not in each
consumer. Four implementations would be four chances to drift, and a client registered
later would arrive unprotected. The boundary where untrusted text crosses into a model
context is exactly the boundary the tool contract already defines, so one place covers all
four and everything added after them — the same argument that made one stdio server serve
three clients.

- `title`, `excerpt`, `company` sanitised; pattern hits attached per article as
  `untrusted_content_flags`; a `_security` block states the text is data to report on,
  never instructions to follow.
- **Reports, never withholds.** Dropping an article on a regex match would let anyone erase
  a company from the platform's coverage by publishing one sentence.
- **Fails open, asserted in a test.** A payload that will not parse — an error body, a 404 —
  passes through untouched. Dropping every article because parsing failed would be a
  self-inflicted denial of service while the structural defence still holds.

Verified against the redeployed API and over the real MCP protocol. 26 tests in the file,
54 across the suite.

- Status: [x] Done (2026-08-03). **Remaining**: `get_news_sentiment` and the other
  aggregate tools return platform-computed numbers and are not an injection surface, but
  any future tool that returns third-party text must route through `_guard_articles` — the
  boundary only holds if new tools use it.

---

## P. Portfolio Holdings

> **Superseded 2026-10-22.** The holdings that are actually used now live in quant_ai on the host
> (`quant_ai/markets/`, SQLite), moved there from job_agent's dashboard together with global
> markets and the daily briefs — see **Q.0**. The `quant_api` / MySQL holdings below are
> deprecated; `get_my_holdings` / `get_my_transactions` read quant_ai first and fall back to them.

### P.1 Manual holdings tracker

**Goal**: Record what is actually held. Everything the platform currently calls a "position" is synthetic — `track_positions.py` mechanically opens the day's top-5 signals and closes on rule triggers. That is a strategy simulation, not a portfolio, and there is nowhere to say "I own 10 NVDA from 2026-05-12".

**Data**: a `portfolio_holdings` collection — symbol, quantity, entry price, entry date, note, open/closed — plus an optional cash balance, so a weight is a share of total capital rather than a share of whatever happens to be invested.

**Surface**:
- `quant_api` — CRUD endpoints under `/api/portfolio/holdings`
- `quant_ui` — a holdings page with a table and free-form add / edit / close
- `mcp_server.py` — a read-only `get_my_holdings` tool, which makes the portfolio visible to Claude Desktop, Codex, and quant_ai's agent at once

**Why first**: both F.17 and G.1 depend on it. Neither position sizing nor a "≤5% per position" guardrail means anything measured against a portfolio nobody owns.

**Handling**: holdings are personal financial data. They stay in the local database and must never reach a seed file, a test fixture, or a commit.

**Delivered (2026-07-26)**

- `HoldingService.replay()` is a pure fold over the trade log, extracted specifically so
  the money maths is testable without a database or a quote provider. 10 unit tests:
  weighted average across mixed buys, realised P&L priced against the average *at the
  time of the sale* (folding from the end state gets this wrong), sell leaving the average
  untouched, full exit then re-entry starting fresh, overselling capped and flagged rather
  than producing a negative position.
- `QuoteService` caches Finnhub quotes for 20s. The free tier is 60 requests/minute and
  serves one symbol per call, so a page polling 20 symbols every 5s would be rate-limited
  immediately; the UI polls the cache instead and only a miss reaches Finnhub. Off-hours
  the TTL stretches to 15 minutes since prices are not moving. On failure or a missing
  token it serves the last `stock_prices_history` close tagged `source: daily-close`, and
  the UI labels it — a stale number presented as live is worse than an honest close.
- `IllegalArgumentException` now maps to 400/404 in `ApiExceptionHandler`; without it the
  hand-rolled input checks surfaced as 500s with no actionable message.
- MCP gained `get_my_holdings` and `get_my_transactions` (8 tools total). Because the
  server is the tool contract, Claude Desktop, Codex and quant_ai's agent all gained the
  portfolio at once with no client changes.

- Status: [x] Done — API + UI + MCP; F.17 is unblocked

---

## N. News Propagation — events outside the universe

**The problem.** ChangXin Memory listed and rose 471%; US memory names fell the same day.
The platform saw nothing, because it matches articles to companies by name and no article
about ChangXin mentions Micron. Generalised: any event whose *source* sits outside the
100-symbol universe — a foreign competitor, an export-control ruling, a war, an OPEC
decision — is invisible, however much it moves the portfolio.

**What is not the problem.** The corpus already covers these entities: ChangXin appears in
173 articles, 53 of them in 2026. The N.0 repair also revealed 5,688 recent articles that
name no covered company at all — general and macro news, sitting unused. The raw material
is there. What is missing is a propagation mechanism and, more importantly, evidence that
propagation predicts anything.

**The trap this series is designed around.** The motivating observation — "memory fell
today, ChangXin listed today, therefore ChangXin caused it" — is a post-hoc narrative.
Financial media supplies three plausible causes for every move. Building the capture
without the validation produces a machine that always has an explanation and never has an
edge. N.4 is therefore not a checkpoint at the end; it is the deliverable, and N.1–N.3
exist to feed it.

**How the industry does this**, for calibration:

| Approach | Who | Mechanism |
|---|---|---|
| Entity relationship graphs | Bloomberg SPLC, FactSet Revere, LSEG | curated competitor / supplier / customer edges; news propagates N hops |
| Thematic tagging | RavenPack, Accern | articles tagged by theme; themes mapped to exposure |
| Statistical co-movement | Barra, PCA factor models | peer groups learned from returns rather than curated |
| Event studies | standard academic method | distribution of abnormal returns after an event |

That Bloomberg and RavenPack charge heavily for exactly this says both that it is valuable
and that it is hard.

---

### N.0 Intraday collector schema repair — **done**

The finnhub / newsapi / yahoo collectors wrote `{source, title, description, content, url,
impact, publishedAt, collectedAt, language, meta}` — no `date`, no `symbol`. GDELT queries
per company and therefore writes both. Since `slm_company_match_v2.build_query()` requires
`{"symbol": {"$exists": True, "$ne": None}}`, everything the intraday collectors wrote from
2026-04-13 onward was invisible to the matcher: 9,636 articles, never labeled, never
featurised, never in a signal.

The consequence is exactly the capability being asked for here — same-day alerting was
impossible because same-day news never left the raw collection.

`collectors/news/_canonical.py` derives `date` from `publishedAt` in GDELT's
`YYYYMMDDHHMMSS` form and assigns a candidate symbol by keyword-matching the 100 company
rule files. Design notes worth keeping:

- **Candidate, not verdict.** The SLM validator downstream is where match accuracy is
  already engineered; this layer only has to get an article *into* that queue.
- **Conservative by construction.** AAPL's primary keyword is `Apple Inc.`, not bare
  `Apple`, so "Apple to pay Italy 318 million euros" gets no symbol. That is the right
  trade: a wrong symbol pollutes a ticker's sentiment aggregate permanently, a missing one
  costs a single article, and the validator can reject a bad candidate but never sees an
  article that has none.
- **One symbol per article**, because `url` is UNIQUE on `news_articles` — the same
  one-article-one-company shape GDELT produces.
- **Unmatched articles are kept.** 5,688 of the backfilled set name no covered company;
  they are macro and general-market news, which is the input N.1–N.3 need.

- Status: [x] Done — collectors patched, `tools/backfill_intraday_canonical.py` written and
  dry-run verified (41% match rate)

---

### N.1 Influencer entity registry

**Goal**: name the entities that move the portfolio without being in it.

A dictionary parallel to `company_rules`: foundries and memory makers (ChangXin, TSMC,
Samsung, SK Hynix, ASML), macro actors (OPEC, the Fed, export-control bodies), named
conflicts and their commodity exposure.

Each entry maps to affected symbols **with a direction**, because direction is not
derivable from the entity. A competitor's successful IPO is bearish for incumbents; rising
DRAM prices are bullish for the same names; the entity is identical in both.

- Status: [ ] Pending (1 day)

---

### N.2 Theme labels in the labeling pipeline

**Goal**: cover what an entity list cannot enumerate in advance.

The dual-LLM pass already reads every article, so a theme tag costs almost nothing at the
margin. Themes: memory cycle, AI capex, export controls, energy, conflict, rates, supply
chain.

Entity registry and themes are complementary — the registry is precise about known actors,
themes catch the ones nobody listed.

- Status: [ ] Pending (1 day)

---

### N.3 Theme → symbol exposure matrix

**Goal**: which of the 100 are exposed to "DRAM oversupply", and how much.

Seeded from the `sector` field already in `daily_symbol_features`, extended by LLM proposal
under human review. Expressed as an exposure weight rather than a boolean: MU is not
exposed to the memory cycle in the same degree as AAPL is.

- Status: [ ] Pending (1.5 days)

---

### N.4 Event-study validation — **the deliverable**

**Goal**: decide whether any of this predicts, or merely explains.

For each theme and influencer event: the distribution of **excess** returns for exposed
symbols over 1 / 5 / 20 days. Excess, not absolute — `excess_ret_*` already exists in the
feature store, and reporting absolute returns would let "memory fell on a day the whole
market fell" masquerade as a finding.

Two failure modes get measured rather than assumed away:

- **Hindsight bias** — the event list is fixed before returns are examined. Starting from a
  move and hunting for its cause reliably finds one.
- **Statistical power** — report the count of *independent* events per theme. A theme
  firing five times a year cannot support a factor whatever its point estimate; that is a
  result to publish in the report, not a reason to suppress the theme.

A negative result here is a successful outcome for this stage. It redirects N.5 rather than
blocking it.

- Status: [ ] Pending (2 days)

---

### N.5 Holdings alerting on validated themes

Extends F.16 from symbol-scoped to theme-scoped, gated on N.4: only themes shown to predict
generate an alert.

Themes that explain without predicting stay available as a research tool through the MCP
surface. Telling the user *why* a position moved today is genuinely useful and is a
different claim from telling them what to buy tomorrow. Keeping the two apart is the
discipline the series is built around, and conflating them is how a news feature becomes a
losing strategy.

- Status: [ ] Pending (1 day)

---

## J. Pipeline Workflow Orchestration & Daily Enrichment

### J.0 Current Pipeline Overview

The daily pipeline is driven by `launchd → scheduler/task.py` using the Python `schedule` library with fixed clock times. All 14 daily tasks and their implicit dependencies:

```
05:15  gdelt_backfill ──────────────────────────────────────────────────────┐
06:00  inst_13f (Sunday only) ──────────────────────────────────────────────┤
*/30m  finnhub_news / newsapi_news / yahoo_news (continuous, all day) ──────┤
                                                                             │
07:30  daily_price_quotes ──────────────────────────────────────────────────┤
07:45  premarket_signals ───────────────────────────────────────────────────┤
07:48  analyst_consensus ───────────────────────────────────────────────────┤
07:50  macro_indicators ────────────────────────────────────────────────────┤
                                                                             │ all above
                                                                             ▼
08:00  daily_symbol_features ──────── (depends on all data collectors above)
                                                                             │
                                                                             ▼
08:30  score_daily_signals ──────────────────── (depends on features)
                                │
              ┌─────────────────┴──────────────────┐
              ▼                                     ▼
08:40  track_positions                  08:45  backtest_portfolio
              │
              ▼
09:00  data_quality_check
20:30  retail_sentiment  (standalone, next-day feature input)
```

**Problem with pure time-based scheduling:**

| Risk | Current behavior | Desired behavior |
|------|-----------------|-----------------|
| Price collector fails at 07:30 | Features still run at 08:00 with stale prices | Wait for price success; skip or alert if failed |
| GDELT backfill runs >2.5 hours | Features use yesterday's GDELT news | Wait for backfill; or soft-dependency with timeout |
| Any task fails | No notification; next task starts anyway | Alert + optionally skip downstream tasks |
| Tasks have hard-coded time gaps | 30-min buffer between price (07:30) and features (08:00); fragile | Dependency → task B starts immediately when A succeeds |

---

### J.1 Airflow DAG Migration (Dependency-Based Pipeline Orchestration)

**Goal**: Replace the fixed-clock `schedule` library in `task.py` with proper Airflow DAGs that enforce task dependencies. Airflow is already deployed in Docker (`airflow-webserver:15060`); DAGs exist but haven't been validated end-to-end on the new machine.

**Target DAG: `daily_pipeline_dag`**

```
gdelt_backfill (05:15 start)
       │
       │  [timeout 4h, soft dependency]
       │
daily_price_quotes ──► premarket_signals ──┐
                         analyst_consensus ──┤
                         macro_indicators  ──┤
                                             │ all done
                                             ▼
                              daily_symbol_features
                                             │
                                             ▼
                              score_daily_signals
                                    │           │
                                    ▼           ▼
                              track_positions  backtest_portfolio
                                    │
                                    ▼
                              data_quality_check
```

**Secondary DAGs (keep separate):**
- `news_collection_dag`: finnhub/newsapi/yahoo every 30 min (TriggerRule.ALL_DONE, no upstream dep)
- `weekly_dag`: inst_13f on Sunday 06:00
- `evening_dag`: retail_sentiment at 20:30

**Key Airflow advantages over current task.py:**
1. Task failure stops downstream tasks automatically (no wasted compute on stale data)
2. Visual DAG view in Airflow UI — see which step failed without log-diving
3. Retry with backoff: `retries=2, retry_delay=timedelta(minutes=5)`
4. Cross-task XComs: backfill task can pass "rows written" count to features task
5. Backfill single DAG runs for missed dates without re-running everything

**What needs to be built:**
1. `airflow/dags/daily_pipeline_dag.py` — wire existing Python scripts as BashOperator tasks with dependencies (1 day)
2. `airflow/dags/news_collection_dag.py` — 30-min news collectors with overlap detection (1 day)
3. `airflow/dags/weekly_dag.py` — Sunday inst_13f + weekly performance summary (0.5 days)
4. Alert hook: `on_failure_callback` → writes to MongoDB `pipeline_alerts` collection; quant_api polls and sends push notification (1 day)
5. Disable corresponding jobs in `task.py` / launchd after each DAG is verified (migration, not big-bang switch)

- Status: [ ] Pending (3.5 days; Stage 7.2.2 prerequisite)

---

### J.2 Daily SLM Company Match for Realtime News (Critical Pipeline Gap)

**Goal**: Run SLM company matching on new Finnhub/NewsAPI/Yahoo articles every morning so they contribute to daily sentiment features.

**Current gap (critical):**

```
Finnhub/NewsAPI/Yahoo collectors write to news_articles
   → articles have NO "symbol" field
   → daily_symbol_features.py filters {"symbol": {"$exists": true}}
   → realtime news is COMPLETELY excluded from sentiment features
   → sentiment features only use GDELT-matched articles
```

This means `avg_sentiment_3d`, `news_burst_20d`, `high_signal_count`, and other news-based features ignore ~30–50% of available news coverage for most stocks.

**Fix**: Add a daily `slm_company_match_daily` job at ~07:55, just before `daily_symbol_features`:

```python
# Pseudocode for slm_company_match_daily.py
articles = db.news_articles.find({
    "symbol": {"$exists": False},   # unmatched realtime articles
    "publishedAt": {"$gte": three_days_ago}   # only recent articles
})
for article in articles:
    matched_symbol = run_slm_match(article["title"] + " " + article.get("content", ""))
    if matched_symbol:
        db.news_articles.update_one(
            {"_id": article["_id"]},
            {"$set": {"symbol": matched_symbol, "match_source": "slm_daily"}}
        )
```

**Implementation:**
1. Write `research/slm_company_match_daily.py` that calls `slm_company_match_v2.py` matching logic on articles with `publishedAt >= 3 days ago AND symbol not exists` (1 day)
2. Add `ENABLE_SLM_MATCH_JOB` in `task.py` scheduled at `07:55` (before `08:00` features) (0.5 days)
3. In Airflow: add as a node between news collectors and `daily_symbol_features`

**Expected impact:**
- Finnhub articles (very company-specific) → high match precision; adds targeted earnings/analyst news to sentiment
- NewsAPI/Yahoo → moderate precision; adds broad market context
- `avg_sentiment_3d` and `high_signal_count` features become richer without any feature engineering changes

**Prerequisite:** Requires LM Studio `qwen3.5-4b` loaded (same as GDELT SLM filter; no new model needed)

- Status: [ ] Pending (1.5 days)

---

### J.3 Daily LLM Sentiment Enrichment for New Articles

**Goal**: Run Gemma 3B + Qwen 4B dual-pass labeling on new articles each morning so `llm_sentiment_final` stays current (currently only historical 845K articles have labels; new daily articles don't get scored).

**Current gap**: Articles arriving via Finnhub/NewsAPI/Yahoo daily do not have `llm_sentiment_final` or `event_type` fields. The LLM labeling was a one-time batch job on historical data.

**Daily enrichment job** (`research/llm_enrich_daily.py`):

```
07:56 (after J.2 company match, before 08:00 features)
  1. Find articles: {symbol: {$exists: true}, llm_sentiment_final: {$exists: false}, publishedAt >= 3d}
  2. Pass A: Gemma 3B → raw_sentiment, event_type
  3. Pass B: Qwen 4B → cross-check; if agree → final label; if disagree → flag
  4. Write llm_sentiment_final, event_type, llm_confidence to news_articles
```

**Volume estimate**: ~500–2,000 new company-matched articles per day (Finnhub + NewsAPI + Yahoo + new GDELT);
at ~5 articles/sec (Gemma 3B), two-pass takes ~3–6 minutes → fits in the 07:56–08:00 window.

**Implementation:**
1. Write `research/llm_enrich_daily.py` using the same dual-pass logic as `llm_enrich_articles.py` but filtered to last-3d unscored articles (1 day)
2. Add `ENABLE_LLM_ENRICH_JOB` in `task.py` at `07:56` (0.5 days)
3. In Airflow DAG: `slm_company_match_daily` → `llm_enrich_daily` → `daily_symbol_features`

**Prerequisite:** Requires LM Studio `gemma3:4b` + `qwen3:4b` loaded (or a single Qwen3.5-4b if using single-pass for speed)

- Status: [ ] Pending (1.5 days; do after J.2)

---

### J.4 Pipeline Failure Alert System

**Goal**: When any daily pipeline task fails, send an immediate push notification so failures are caught before the trading day starts, not discovered hours later by checking logs.

**Current state**: Failures are logged to `pipeline_scheduler.log` only. No proactive notification.

**Implementation options (pick one):**

| Option | Description | Effort |
|--------|-------------|--------|
| Email alert | `smtplib` sends email on task failure | 0.5 days |
| Slack webhook | `POST` to Slack incoming webhook URL | 0.5 days |
| MongoDB + UI poll | Task writes `{status: "failed"}` to `pipeline_alerts`; quant_ui polls | 1 day |
| macOS notification | `osascript -e 'display notification...'` | 0.5 days |

**Recommended**: Slack webhook (works remotely; zero setup on client side; free).

**What to alert on:**
- Any `run_script_once` returns non-zero exit code
- `data_quality_check` overall status is "warn" or "fail"
- `track_positions` triggers a stop-loss exit
- `gdelt_backfill` exits with `/Volumes/Data4T` mount error (the known failure mode)
- `score_daily_signals` produces 0 LONG signals

**In Airflow**: `on_failure_callback` + `on_success_callback` for key tasks (no code change to pipeline scripts).

**In task.py (before Airflow migration)**: Wrap `run_script_once` to check `result.returncode` and call `send_alert(job_name, stderr)` on failure.

- Status: [ ] Pending (0.5 days; high impact, low effort)

---

### J.5 Intraday Position Stop-Loss Monitor

**Goal**: Check live prices during market hours (09:30–16:00 ET) every 5 minutes for held positions, and trigger a stop-loss alert instantly when price falls through the stop level — instead of waiting for the 08:40 `track_positions` next morning.

**Current behavior**: `track_positions.py` runs once at 08:40 and looks at yesterday's closing price. If a position drops 8% intraday, the stop-loss is not detected until next morning's close.

**Target**: Real-time intraday monitoring using Alpaca WebSocket streaming (the same WebSocket planned for live trading).

```
scheduler/intraday_monitor.py   (long-running process during market hours)
  │
  ├─ On startup: load current positions from MongoDB (track_positions.py output)
  │              load stop-loss levels (entry_price × (1 - stop_pct))
  │
  ├─ Connect to Alpaca WebSocket: subscribe to live quotes for held symbols
  │
  ├─ On each price tick:
  │    if current_price < stop_loss_level:
  │        → send Slack/email alert: "STOP-LOSS TRIGGERED: {symbol} @ {price}"
  │        → write to MongoDB: {event: "stop_loss_breach", symbol, price, timestamp}
  │        → if live trading enabled: submit sell order via Alpaca REST API
  │
  └─ 16:00 ET: close WebSocket, write daily EOD position summary
```

**Scheduler integration:**
- Add `ENABLE_INTRADAY_MONITOR_JOB = true` in `.env`
- `ensure_long_running("intraday_monitor", ...)` at 09:28 ET daily
- Kill/restart handled by process poll loop (already in `task.py`)

**Prerequisites:** Alpaca API key (needed for G.1 live trading anyway); no new models needed.

- Status: [ ] Pending (2 days; do after G.1 Alpaca integration)

---

### J.6 Weekly Performance Summary Report

**Goal**: Every Sunday after `inst_13f` completes, auto-generate a weekly summary: signal IC for the past week, positions opened/closed, P&L vs SPY, top/worst performers, factor attribution.

**Implementation:**
1. Write `research/weekly_summary.py` that reads last-7d `daily_signals` + `portfolio_positions` + `portfolio_performance` (1 day)
2. Format as JSON → quant_api `GET /api/weekly-report` → quant_ui weekly report tab (0.5 days)
3. Optional: send as Slack message or email attachment

- Status: [ ] Pending (1.5 days; do after J.4 alert system)

---

### J. Priority Summary

| Priority | Item | Effort | Depends on |
|----------|------|--------|-----------|
| ⭐⭐⭐ | **J.2 Daily SLM company match** (fills critical pipeline gap; realtime news → features) | 1.5 days | LM Studio qwen3.5-4b |
| ⭐⭐⭐ | **J.4 Pipeline failure alerts** (Slack webhook on task failure) | 0.5 days | None |
| ⭐⭐ | **J.3 Daily LLM sentiment enrichment** (daily Gemma+Qwen on new articles) | 1.5 days | J.2, LM Studio gemma3+qwen |
| ⭐⭐ | **J.1 Airflow DAG migration** (dependency-based DAG; replaces time-gap scheduling) | 3.5 days | Stage 7.2.2 |
| ⭐⭐ | **J.5 Intraday stop-loss monitor** (Alpaca WebSocket real-time) | 2 days | G.1 Alpaca |
| ⭐ | **J.6 Weekly performance summary** | 1.5 days | J.4 |

---

### G.1 Live Trading Execution (Automated Trading)

**Goal**: Connect the existing signal pipeline to a real broker API so that daily signals automatically place live orders, with position reconciliation and risk guardrails. This is the final step that turns the platform from a research/paper-trading system into a real execution system.

**Three-stage progression:**

```
Stage 1 (paper → broker paper account)   ← safest starting point
  track_positions.py signals
      ↓
  Alpaca Paper Trading API (free, no real money)
      ↓
  Real order book simulation with live market prices

Stage 2 (live trading, small size)
  Same signal pipeline
      ↓
  Alpaca Live API / Interactive Brokers TWS API
      ↓
  Real orders, real fills, real P&L

Stage 3 (full automation)
  launchd triggers score_daily_signals at 08:30
      ↓
  live_trader.py reads top-N signals → places market orders at open
      ↓
  Position monitor runs intraday → fires stop-loss orders if triggered
      ↓
  EOD reconciliation: compare expected vs actual fills
```

**What needs to be built:**

| Component | Description | Effort |
|-----------|-------------|--------|
| `research/live_trader.py` | Read top-N LONG signals from MongoDB → submit buy orders via broker API | 2 days |
| `research/order_manager.py` | Track open orders, handle partial fills, cancel stale orders | 2 days |
| `research/position_reconciler.py` | Compare paper positions vs broker positions; alert on drift | 1 day |
| Broker API integration | Alpaca REST API (simpler) or IBKR TWS API (more powerful) | 2-3 days |
| Pre-trade risk checks | Max position size, daily loss limit, no-trade list, market hours check | 1 day |
| Alert system | Kafka → Spring Boot → push notification on fill / stop-loss / error | 1 day |

**Pre-trade risk guardrails (non-negotiable before going live):**
- Max single position: 5% of portfolio
- Max daily drawdown kill-switch: halt all trading if down >3% intraday
- No trading in first/last 15 minutes of session (wide spreads)
- Whitelist: only trade symbols already in the 100-stock universe
- Position size = `kelly_fraction × account_equity / entry_price`, capped at 100 shares for initial testing

**Broker options:**

| Broker | API | Cost | Best for |
|--------|-----|------|---------|
| Alpaca | REST + WebSocket, Python SDK | Free (commission-free US stocks) | Starting point; easiest integration |
| Interactive Brokers | TWS API (Python `ib_insync`) | Low commission | Professional; supports options/futures later |
| Webull | Unofficial API | Free | Not recommended (unofficial) |

**Recommended starting point**: Alpaca paper account → validate that orders match signal intent → switch to live with $1K–$5K test capital.

**Key difference from paper trading:**
- `track_positions.py` simulates fills at closing price → no slippage, no partial fills, no API errors
- Live trading introduces: slippage, order rejection, partial fills, API downtime, margin calls
- Need fill confirmation loop: place order → poll for fill → update position → log to MongoDB

**Interview framing:**
*"The platform currently runs paper trading — the full signal-to-position pipeline is live, with automated entry/exit and stop-loss monitoring. The next engineering step is wiring the existing signals to a broker API (Alpaca) with pre-trade risk guardrails: position sizing, daily loss limits, and a kill-switch. The architecture is already designed for this — it's an execution layer addition, not a redesign."*

- Status: [ ] Pending (2–3 weeks for Stage 1 + Stage 2)

---

### G.2 Stock Universe Expansion

**Goal**: Grow the current 103-stock universe to cover a broader range of sectors and international names.

**Current state (2026-07-15):**
- 100 original stocks (US tech, SaaS, biotech, financials, consumer, industrials)
- 3 just added (STX, WDC, HXSCL) → **103 total**
- Storage sector is now complete: MU (DRAM), HXSCL (DRAM/NAND), STX (HDD), WDC (HDD/NAND)

**Planned expansions:**

| Phase | Symbols | Notes | Effort |
|-------|---------|-------|--------|
| Phase 1 (near-term) | STX, WDC, HXSCL | ✅ Done 2026-07-15 | 0 days |
| Phase 2 (energy/materials) | XOM, CVX, NEE, LIN, APD | Complete sector diversification; no current energy/materials coverage | 2 days |
| Phase 3 (international ADRs) | BABA, JD, PDD, BIDU, SE, GRAB | US-listed ADRs for China/SE Asia tech; significant news coverage available | 2 days |
| Phase 4 (broader S&P) | SPG, PLD, AMT (REITs), BRK-B, BAC, WFC | Financials/REITs expansion; less news-driven, lower priority | 3 days |

**What adding a new symbol requires:**
1. Add to `COMPANY_UNIVERSE` in `slm_company_match_v2.py` (keywords for news matching)
2. Collect price history: `stock_prices_history` via `daily_price_collector/collector.py`
3. Collect news history: `news_articles` via GDELT backfill (already running, just needs symbol added)
4. Run `company_match_rescore` to label historical articles for the new symbol
5. Rebuild features: `daily_symbol_features.py --symbol NEW_SYMBOL` or full rebuild
6. Re-run backtests to verify IC is stable with the expanded universe

**Note on HXSCL (SK Hynix):** Listed on US OTC markets (Pink Sheet: HXSCL). yfinance can pull price data. News coverage available via GDELT (English-language coverage of Korean semiconductor industry is substantial due to global supply chain relevance).

**Note on hourly/intraday data:** Not planned. Current strategy holds 5–60 days; daily + pre-market/after-hours gaps are sufficient. Intraday bars would only help with sub-day execution timing, which is not a priority until Stage 2 live trading is proven.

- Status: Phase 1 ✅ Done; Phases 2–4 [ ] Pending (low priority, expand only after live trading is validated)

---

## L. Multi-Frequency Strategy Layer (多周期策略扩展)

### L.0 背景：新闻信号的 IC 衰减规律

新闻驱动的信号 IC 并非在所有时间周期均等，学术研究和实践均表明：

```
信号强度（IC）随持仓周期变化示意：

    IC
  0.15 │▓▓
  0.12 │▓▓▓
  0.09 │▓▓▓▓▓
  0.06 │▓▓▓▓▓▓▓▓       ← 当前系统在此区间 (5-60d, IC≈0.059)
  0.03 │▓▓▓▓▓▓▓▓▓▓▓▓
  0.00 └──────────────────────────────────
       隔夜  1d  2d  5d  10d  20d  60d
```

**核心洞察**：新闻对价格的冲击在发布后数小时到隔夜最为集中，随后被市场消化。
当前系统只捕捉了 5–60 天的"尾部效应"，最强的短期反应被丢弃了。

**两类可扩展的短周期策略：**

| 策略 | 持仓周期 | 需要新基础设施 | 难度 |
|------|---------|--------------|------|
| L.1 隔夜新闻动量 | 收盘买入 → 次日开盘卖出 | 仅需 Alpaca 下单 | 低 |
| L.2 日内快速信号 | 1–4 小时 | 小时线 + Alpaca WebSocket | 高 |

---

### L.1 隔夜新闻动量策略 (Overnight News Momentum)

**原理**：下午盘中出现的重大正面新闻，往往在当日收盘价还未完全反映，隔夜 gap 上涨是可预测的超额收益来源。

**策略逻辑：**

```
每日 15:30 ET (收盘前 30 分钟)
  │
  ├─ 扫描过去 4 小时内所有公司匹配的新闻文章
  │    条件: publishedAt >= 11:30 AND symbol IS NOT NULL
  │
  ├─ 计算"新闻冲击分"：
  │    sentiment_spike = avg_llm_sentiment (今日) - avg_llm_sentiment (过去5日均值)
  │    news_burst     = 今日文章数 / 过去20日均值
  │    overnight_score = sentiment_spike × news_burst × analyst_surprise_weight
  │
  ├─ 选取 overnight_score 排名前 3 只股票 (同时满足 score > 阈值)
  │
  └─ 执行:
       15:55 ET: 市价买入 (收盘前 5 分钟，接近收盘价)
       次日 09:35 ET: 市价卖出 (开盘后 5 分钟，锁定隔夜 gap)
```

**为什么这个策略用现有基础设施就能实现：**
- 新闻采集：Finnhub/NewsAPI/Yahoo 每 30 分钟一次，已覆盖日内新闻 ✅
- 情绪打分：完成 J.3 后，新文章有 `llm_sentiment_final` ✅
- 下单执行：G.1 Alpaca 集成后，market order 只需一行 SDK 调用 ✅
- 不需要小时线，不需要新的数据基础设施 ✅

**新增的 pipeline 任务：**

```
scheduler/task.py 中新增:
  15:30 ET  overnight_signal_scan   # 扫描当日新闻冲击
  09:35 ET  overnight_exit          # 隔夜仓位出场
```

**因子验证（先做，再上线）：**
1. 计算历史 overnight return (收盘价 → 次日开盘价) 作为新标签
2. 用现有 `llm_sentiment_final` + `news_burst` 跑单因子 IC (目标: IC > 0.08)
3. 回测：隔夜策略的 Sharpe 预期比 20d 策略更高但波动也更大
4. 容量限制：隔夜策略仓位必须小（每笔 ≤ 2% 净值），因为流动性在收盘前变差

**与当前中频策略的关系：**
- 两套策略**完全独立运行**，不共享仓位预算
- 中频策略 (5–60d)：持仓 top-5，占用 80% 资金
- 隔夜策略：持仓 top-3，占用 ≤ 10% 资金（高换手，小仓位）
- 可以在同一个 Alpaca 账户下并行运行，用 `strategy_type` 字段区分 MongoDB 持仓记录

- Status: [ ] Pending (4 days; do after G.1 Alpaca + J.3 LLM enrichment)

---

### L.2 日内快速信号 (Intraday Fast Signal)

**原理**：重大新闻发布后，价格在最初 30–120 分钟内的动量往往持续，随后均值回归。捕捉这个初始冲击窗口。

**需要的新基础设施：**
- **小时线历史数据**：Alpaca bars API (`timeframe=1Hour`)，用于计算日内 realized volatility 和动量基准
- **Alpaca WebSocket 实时行情**：J.5 盘中监控已规划，可复用
- **更快的新闻处理**：目前 30 分钟一次采集；日内策略需要缩短到 5 分钟以内（Finnhub WebSocket 实时新闻推送）

**策略逻辑（简化版）：**

```
Finnhub 实时新闻推送 (WebSocket)
  │
  ├─ 新文章到达 → 实时 SLM company match → 情绪打分
  │
  ├─ 若 sentiment_spike > 阈值 AND 当前时间在 09:45–15:00 ET 之间:
  │    → 立即查询 Alpaca 实时报价 (bid/ask spread)
  │    → 若 spread < 0.1% AND 买入信号:
  │         → 市价买入，设置 2% 止损 + 60 分钟时间止损
  │
  └─ 持仓期间: 每 5 分钟检查动量是否衰减 → 动态出场
```

**难度较高，原因：**
- 需要 Finnhub WebSocket 实时新闻（替换现有 30 分钟轮询）
- 小时线 backfill（103 只股票 × 2 年 × 6.5h）
- 日内仓位管理更复杂（需要盘中止损 + 时间止损双重逻辑）
- 滑点和手续费对日内策略影响更大（round-trip cost 对 1–4h 持仓影响 > 对 20d 持仓 10 倍）

**前置条件**：L.1 隔夜策略验证 + Alpaca live trading 稳定运行后再考虑。

- Status: [ ] Pending (2 weeks; do after L.1 is validated live)

---

### L.3 5-Minute Bar Data Infrastructure (5分钟线数据基础设施)

**Goal**: 采集并维护 103 只股票的 5 分钟 OHLCV 数据，作为 L.2 日内策略和 J.5 盘中止损监控的数据基础。

**为什么选 5 分钟而非 1 分钟：**

| 粒度 | 年数据量 (103只) | 新闻反应窗口捕捉 | 噪声 | 推荐 |
|------|----------------|----------------|------|------|
| 1分钟 | ~1,200万行 | 过细，bid-ask spread 主导 | 极高 | ❌ |
| **5分钟** | **~240万行** | **覆盖 30–90 分钟反应窗口** | **可控** | **✅** |
| 1小时 | ~20万行 | 太粗，错过入场时机 | 低 | ❌ |

**数据来源**: Alpaca Markets bars API (`/v2/stocks/{symbol}/bars?timeframe=5Min`)
- 免费 tier 提供 2 年历史 5 分钟线
- 速率限制: 200 req/min（103 只股票 backfill 约需 20 分钟）

**存储设计**:

```
MongoDB collection: stock_prices_5min
{
  "symbol":    "AAPL",
  "timestamp": ISODate("2026-07-16T14:30:00Z"),   // UTC, 5min bar open time
  "open":      220.15,
  "high":      220.48,
  "low":       220.02,
  "close":     220.35,
  "volume":    125430,
  "vwap":      220.28
}
Index: { symbol: 1, timestamp: -1 }  (unique compound)
```

预估存储：240万行/年 × 平均 100 bytes ≈ **240MB/年**，两年历史约 500MB，可接受。

**实现步骤：**

1. **Backfill 脚本** `stock_collector/price_collector/5min_history_collector.py` (1.5 days)
   - 对 103 只股票依次调用 Alpaca bars API，拉取过去 2 年 5 分钟线
   - 写入 `stock_prices_5min`，建立 `{symbol, timestamp}` 唯一索引
   - 进度断点续传：已存在的数据跳过，从最新 timestamp 续拉

2. **每日增量采集** (0.5 days)
   - 新增 `ENABLE_5MIN_PRICE_JOB=true` 在 `.env`
   - 在 `task.py` 中添加每日 `16:35 ET` 触发（收盘后 5 分钟）
   - 只拉当天 09:30–16:00 的 5 分钟线（78 根 × 103 只 = 8034 条/天）

3. **可复用的新特征** (加入 daily_symbol_features.py 或新建 intraday_features.py)

   | 特征 | 计算方式 | 用途 |
   |------|---------|------|
   | `realized_vol_1d` | 当日 78 根 5min 收益率标准差 × √78 | 更准确的日内波动率估计 |
   | `intraday_momentum_1h` | (14:30 收盘 - 13:30 收盘) / 13:30 收盘 | 尾盘动量因子 |
   | `vwap_deviation` | (收盘价 - VWAP) / VWAP | 偏离 VWAP 程度 |
   | `open_gap_fill_ratio` | 开盘 gap 在首小时内回填比例 | 趋势 vs 均值回归判断 |
   | `volume_concentration_close` | 最后 30 分钟成交量 / 全天成交量 | 机构尾盘行为 |

4. **L.2 日内策略数据支撑**：5 分钟线提供日内动量基准和 realized vol，替代 Alpaca WebSocket 实时行情在回测中的角色

**与现有 daily price 的关系**：
- `stock_prices_history`（日线）继续维护，用于中频特征和回测，不变
- `stock_prices_5min`（5分钟线）是新增补充，仅用于日内特征和 L.2 策略

- Status: [ ] Pending (2 days total: 1.5d backfill + 0.5d scheduler integration; do before L.2)

---

### L. Priority Summary

| 优先级 | 项目 | 前置条件 | 工期 |
|--------|------|---------|------|
| ⭐⭐ | **L.1 隔夜新闻动量策略** (15:30 情绪扫描→收盘买→次日开盘卖，无需5分钟线) | G.1 Alpaca + J.3 LLM enrichment | 4 days |
| ⭐⭐ | **L.3 5分钟线数据基础设施** (Alpaca API backfill + 每日增量 + 5个日内特征) | G.1 Alpaca API key | 2 days |
| ⭐ | **L.2 日内快速信号** (5分钟线 + Finnhub WebSocket实时新闻 → 日内动量) | L.1 验证通过 + L.3 数据就绪 | 2 weeks |

---

## M. Signal Research Rigor

Hardens the signal research so its claims survive a quant-researcher-style interrogation
(IC significance? out-of-sample? survivorship bias? why not overfit?).

**This section was previously marked low priority. M.7 changes that.** The rest of the
series is about strengthening claims that are broadly sound; M.7 is a confirmed defect
that makes the headline factor invalid, and M.1 is selection bias built into the universe
before any model runs. Those two are blockers — for G.1 live execution, and for quoting
any Sharpe figure without a caveat. M.2–M.6 remain optional polish aimed at QR roles.

Accepted risk, stated plainly: rigorous treatment will probably show the signal is weaker
than the current numbers. That outcome is itself a defensible research finding when written
up honestly, and it is strictly better than discovering it after committing capital.

### M.1 Point-in-Time Universe (kill survivorship & selection bias)
Replace the hand-picked 103-stock tech universe with point-in-time S&P 500 membership
including delisted names. The current universe is the single most attackable weakness:
almost any signal "works" on a winners-only mega-cap list.
- Source historical index membership (incl. delistings), rebuild features/backtests on it
- Keep the 103-stock universe as a separate "tech sleeve" study
- Effort: 1–2 weeks (data sourcing is the hard part) — Status: [ ] Pending

### M.2 Point-in-Time Data Hygiene Audit
- Purge corrupt future-dated articles (2034/2037 timestamps in `news_articles.date`)
- Full-lineage check: for every feature, verify signal-available-time vs data-creation-time
  (news collected_at vs published_at, 13F filing lag, analyst revision lag)
- Effort: 3 days — Status: [ ] Pending

### M.3 IC Statistical Significance
- Rank IC with Newey-West adjusted t-stats (overlapping horizons inflate naive t-stats)
- IC decay curve / half-life per factor; per-year and per-regime IC stability tables
- Effort: 3 days — Status: [ ] Pending

### M.4 Factor Orthogonalization (the core question)
Does news sentiment contain information not already in price? Residualize sentiment
factors against momentum / short-term reversal / size / sector, then measure residual IC.
If residual IC ≈ 0, the "news signal" is repackaged momentum — better to know.
- Effort: 1 week — Status: [ ] Pending

### M.5 Overfitting Defenses
- Reserve a never-touched final holdout window (e.g. last 6 months) for one-shot evaluation
- Experiment registry: log every parameter combination tried (honest denominator for
  deflated Sharpe); report deflated Sharpe alongside raw
- Effort: 2 days — Status: [ ] Pending

### M.6 Research Report Writeup
Paper-style writeup: hypothesis → data → methodology → results → failure cases →
limitations. An honest "post-cost alpha is marginal, but sentiment shows orthogonal
incremental IC in earnings windows" beats a flashy Sharpe 3.0 backtest in any QR interview.
- Effort: 3 days — Status: [ ] Pending

---

### M.7 13F look-ahead leak — **blocker**

**The defect.** `inst_13f_holdings` contains exactly 100 documents, one per symbol, with
fields `{_id, symbol, collectedAt, inst_holding_pct, inst_holding_pct_chg, total_shares}`
— **no date, no quarter, no filing date**. `attach_inst13f_features()` in
`research/features/daily_symbol_features.py` left-joins on symbol alone, and its own
docstring states the intent: *"These values are quarterly; broadcast to all trade_dates for
each symbol."* A feature row dated 2018-03-15 therefore carries institutional holdings
collected in 2026.

**Why it matters more than a normal PIT slip.** `inst_holding_pct_chg` was reported as the
best single factor at **IC +0.198**, the strongest number in the Key Results table. It
scores that well *because* it leaks. Institutions accumulate what has already risen, so
projecting today's holdings backwards across eight years manufactures precisely the
correlation the IC is measuring. The factor is not merely unproven — it is measuring the
future, and it carries weight in `score_daily_signals.py` (0.5–0.6 depending on regime),
so the contamination reaches the live signal, not just the backtest.

**What makes this diagnosable rather than diffuse**: every other alt-data source in the
same file handles time correctly, which is what makes 13F an oversight rather than a design
philosophy.

| Source | Join | Verdict |
|---|---|---|
| analyst | on `YYYY-MM`; docstring says *"avoids lookahead"* | correct |
| retail | symbol + date, 1,365 rows | correct |
| macro | dated, 16,369 rows | correct |
| **13F** | **symbol only, 100 rows, broadcast** | **leaking** |

**Fix.** Source historical 13F with **filing dates** — SEC EDGAR exposes them, and the
45-day statutory reporting lag is the entire point: a Q1 position becomes public in mid-May,
so it may only enter a feature row dated on or after its filing date, never its reporting
period. Join as-of filing date, forward-fill until the next filing.

**If point-in-time 13F cannot be obtained, remove the factor.** Keeping a factor known to
read the future, with a caveat in a footnote, is worse than dropping it: the number stays in
circulation and the weight stays in the scorer. Then re-run the backtest and publish
whatever Sharpe survives — the drop is the finding.

- Effort: 2 days (1 if the decision is removal) — Status: [ ] **Pending — blocks G.1**

---

### M.8 Turnover and capacity reporting

H.1 prices a round trip per position — commission 5bps plus liquidity-tiered slippage
10/30bps, charged on entry and exit, with a filter excluding symbol-dates too thin to
execute. That model is sound per trade. What is missing is **how many trades there are**.

At a 5-day horizon fed by daily signals, turnover may be high enough that a per-trade cost
model which is honest in isolation understates total drag substantially. Report:

- annualised turnover
- transaction cost as a share of gross return
- the capital level at which the liquidity filter begins to bind

The last one converts "this strategy works" into a claim with a size attached. A result
that holds at $50k and not at $5m is a different result, and the difference is the first
thing a professional will ask about.

- Effort: 1 day — Status: [ ] Pending

---

### M.9 Short-side borrow costs

The long-short Sharpe of 0.85 charges commission and slippage on both legs but nothing for
**carrying** the short: no borrow fee, no hard-to-borrow screen, no recall risk. On exactly
the names a negative news-sentiment signal would select, borrow is where it is most
expensive — the correlation between "bad news" and "expensive to short" is not incidental.

Until this is modelled the long-short figure is optimistic by an unmeasured amount, and the
**long-only results are the more defensible ones to quote**.

- Effort: 1 day (a flat borrow-rate assumption is a legitimate first pass, provided the
  assumption is stated) — Status: [ ] Pending

---

### M.12 News syndication inflates the volume features

**Found 2026-07-30, while deduplicating the corpus for R.1** — the 121,970 rows dropped at
index time turned out not to be noise.

**The mechanism.** GDELT ingests each site of a syndication network as a separate article.
One McDonald's story on 2025-11-03 appears **402 times**: byte-identical body (767 chars),
identical sentiment, 402 distinct `*.iheart.com` subdomains. That symbol-day holds **412
rows and 11 distinct titles** — the news-volume features read 412 where the real number of
stories is 11.

`unique_url_count` exists to catch exactly this and cannot: 402 subdomains are 402 distinct
URLs. `unique_source_count` cannot either — `source.name` is absent on GDELT rows so it
falls back to the platform, and its mean is 1.0139. Both dedupe guards were structurally
blind to the dominant duplication mode.

**Measured** (`research/features/measure_syndication_impact.py` — loads the real frames and
runs the production aggregators twice, once on raw input and once deduplicated on
`(symbol, date, title)`; reusing the pipeline's own functions rather than reimplementing
them is the point):

| collection | rows | unique | duplicate |
|---|---|---|---|
| `news_articles` (volume features) | 1,750,295 | 1,494,636 | **14.6%** |
| `news_articles_company_matched_v2` (sentiment) | 851,071 | 729,101 | **14.3%** |

| feature | mean raw | mean deduped | % symbol-days differing | max abs diff |
|---|---|---|---|---|
| `article_count` | 9.104 | 7.650 | 26.4% | 664 |
| `unique_url_count` | 9.104 | 7.650 | 26.4% | 664 |
| `news_count_20d` | 181.65 | 152.65 | **93.2%** | 4019 |
| `news_burst_20d` | 1.101 | 1.059 | **93.6%** | 599 |
| `sent_wavg` | 0.3221 | 0.3224 | 15.1% | 1.253 |
| `sent_std` | 0.3019 | 0.3063 | 15.0% | 1.414 |
| `negative_n` | 1.521 | 1.228 | 5.8% | 363 |

**The damage is in the volume features, not sentiment.** `sent_wavg` barely moves in
aggregate (0.3221 → 0.3224) because a syndicated copy usually carries a sentiment close to
the day's mean anyway. `news_burst_20d` differs on **93.6% of symbol-days** — it is a
rolling ratio, so one contaminated day propagates through the following twenty.

**Why it is a cross-sectional problem rather than a level shift.** Per-symbol duplicate
share runs **2.3% to 52.4%** — a 23× spread, concentrated in consumer brands that local
radio and lifestyle networks syndicate:

    MCD 52.4  SBUX 38.3  MRNA 37.3  TGT 36.6  SPOT 36.4  BA 36.1
    UNH 33.5  PFE 32.8  LLY 32.2  DIS 31.4  NFLX 29.9   (corpus 16.0)

A uniform inflation would cancel in a cross-sectional rank. This does not: it lifts some
names by half and others by nothing, and the lift correlates with sector.

**It reaches the signal.** `news_burst_20d` carries regime weights **0.9 / 0.8 / 0.5 / 0.2**
(RISK_ON / NEUTRAL / STRESSED / RISK_OFF) in `score_daily_signals.py`, and appears in
`train_baseline_models.py` alongside `article_count` and `news_burst_20d_sector_rel`. The
sector-relative variant does not neutralise this — the bias is itself sector-correlated, so
normalising against a contaminated sector mean penalises the cleanest names in a dirty
sector. **This is the M.7 shape again**: a hand-weighted factor in the regime scorer given
high weight on top of an input nobody had validated.

#### M.12 step 2 — measured impact (2026-07-30)

Two shadow feature sets built from the same code at the same moment, differing only in
`NEWS_DEDUPE_SYNDICATION`: `daily_symbol_features_m12_off` and `_m12_on`, 191,467 rows each.
The off build was verified a genuine no-op first — 4,000 sampled symbol-days across
`article_count`, `news_burst_20d`, `news_count_20d`, `sent_wavg`, `unique_url_count`
differed from production on **0 rows**. Dedupe removed 278,327 news rows (16.0%) and
133,169 sentiment rows (15.8%).

**The ML walk-forward barely notices** (rank IC, aggregate):

| target | model | IC off | IC on | delta |
|---|---|---|---|---|
| 60d | Ensemble | 0.0572 | 0.0549 | −0.0023 |
| 60d | Ridge | 0.0491 | 0.0465 | −0.0026 |
| 60d | LightGBM | 0.0413 | 0.0413 | ±0.0000 |
| 20d | Ensemble | 0.0225 | 0.0202 | −0.0023 |

Every cell moves by less than 0.005 and the signs are not consistent — the LightGBM Ranker
gains +0.0051 at 20d and loses −0.0066 at 45d. Without error bars none of this is
distinguishable from noise, and it is **not** being claimed as an effect.

**The regime scorer does notice** (`backtest_portfolio.py`, which imports `compute_score`
and `_WEIGHTS_BY_REGIME` directly — the same path the live signal takes; 132 rebalances,
20d hold, costs on):

| | off (duplicates in) | on (deduped) |
|---|---|---|
| **net Sharpe** | 0.654 | **0.580** |
| net annualised | 19.64% | 16.76% |
| total return | 5.54× | 4.07× |
| gross Sharpe | 0.794 | 0.729 |
| max drawdown | −42.08% | **−39.56%** |
| win rate | 63.64% | **65.15%** |

**This is the M.7 pattern repeating exactly.** The ML models shrug (−0.0023 IC) because a
tree or a ridge treats `news_burst_20d` as one column among a hundred and learns its actual
predictive weight from data. The hand-weighted scorer assigned it **0.9 by fiat** and lost
**0.074 Sharpe** when the input was cleaned. Twice now, the damage from a contaminated
factor has landed almost entirely on the hand-calibrated weights rather than the fitted
ones — **the models at least look at the data before deciding how much to trust a column.**

Note the deduped run has a *better* drawdown (−39.56% vs −42.08%) and a *better* win rate
(65.15% vs 63.64%). It is a lower-return, lower-risk profile, not a uniformly worse one.

**The counter-argument worth stating**: a story syndicated to 402 stations genuinely does
have unusual reach, and reach may carry information. That does not rescue the current
feature — `article_count` claims to count distinct news and does not. If reach is the
signal, it belongs in a named feature that measures reach deliberately and can be tested on
its own, not smuggled in through a broken count.

**Conclusion**: the 0.074 Sharpe was being earned from an artifact of how GDELT ingests
syndication networks. Removing it is correct for the same reason M.7 was correct, and the
published number should come down again.

**Fix, once the impact is known**: deduplicate on `(symbol, date, title)` inside
`load_news_frame()` and `load_llm_sentiment_frame()` rather than at aggregation time, so
every downstream feature inherits it. The collectors should also stop ingesting syndicated
copies, but the feature layer must not depend on that being true.

#### M.12 step 3 — shipped (2026-07-30)

`NEWS_DEDUPE_SYNDICATION` now defaults to **true**; production features rebuilt (191,467
rows, 278,327 news and 133,169 sentiment duplicates dropped). Final published numbers:

| | before M.12 | after |
|---|---|---|
| 20d net Sharpe | 0.69 | **0.58** (gross 0.73) |
| 20d net annualised | 20.9% | **16.8%** |
| 20d max drawdown | −42.1% | **−39.6%** |
| 20d win rate | 63.6% | **65.2%** |
| 60d net Sharpe | 0.73 *(stale)* | **0.60** (gross 0.65) |
| 60d Ensemble rank IC | 0.0563 | **0.0523** |

Per-year 60d Ensemble IC after the fix — still negative in 4 of 9 years, unchanged in shape:

    2018 +0.021  2019 +0.135  2020 +0.220  2021 −0.030  2022 −0.128
    2023 +0.226  2024 −0.037  2025 +0.017  2026 −0.129

**Deployment note.** The Airflow DAGs run host code, not the container:
`_host_common.py` sets `PYTHON = f"{ROOT}/.venv311/bin/python"` and issues
`cd {ROOT} && {PYTHON} {ROOT}/{script}` against `/Users/xiz/Quant_trade/quant_data`. So this
fix reached production the moment the default flipped, with no image rebuild needed — and
the same was true of M.7. Worth recording because the deployed container is genuinely stale
(compose pins `e650994`, the running container is `e165324` from nine days earlier, and
`e650994` was never even pulled locally); that staleness is real but affects nothing on the
daily path, since every `ENABLE_*` job in the container is disabled and the host scheduler
owns the DAGs.

- Status: [x] Done — flag default-on, production rebuilt, numbers republished.
  **Remaining**: the collectors still ingest syndicated copies, so the raw collections keep
  growing 16% faster than the information in them. Fixing it upstream is a separate item —
  the feature layer must keep its own guard regardless, since it cannot depend on the
  collectors being correct.

---

### Deployment drift — verify against the running system, not the repository

Twice now a container has been running an image older than the one `docker-compose.yml`
declares, because CI updates the tag in the compose file and nothing restarts the
container:

| service | was running | declared | consequence |
|---|---|---|---|
| `quant_data` | `e165324` | `e650994` | **none** — the Airflow DAGs run host code (`_host_common.py`: `cd $ROOT && $ROOT/.venv311/bin/python $ROOT/$script`), so M.7 and M.12 reached production without an image build |
| `quant_api` | `9307bbe` | `e70b3cb` | **real** — `/api/news/search` existed in the Java source but not in the running image, so the `search_news` MCP tool returned 404 for all three clients |

The second one went unnoticed because I.6 was marked done on the evidence that the function
existed in `mcp_server.py`. **A file in the repository is not a working feature.** Both were
fixed on 2026-08-03 by `docker compose pull` and recreating the two containers; all ten
platform MCP tools were then called against the deployed API and confirmed to return real
data, rather than confirmed to exist.

The rule this leaves: a status of "done" for anything with a deployed surface needs evidence
from the deployed surface. `quant_airflow:local` will always fail `docker compose pull` —
it is built locally and lives in no registry — which is expected, not a fault.

---

### S.3 Identity that is a principal, not a parameter (found 2026-08-07)

**The observation.** `get_eval_batch(judge_id)` and `submit_judgment(judge_id, judgments)`
take the judge's identity as an argument the caller supplies. Nothing derives it.

**What this is not.** It is not a privilege boundary today and should not be written up as
one. `judge_id` is a label namespace — `claude-desktop`, `codex` — whose purpose is keeping
each judge's labels separable so inter-judge agreement can be measured. There is no user
data behind it, and the platform has one operator.

**Where the cost actually lands: the measurement.** Re-submitting the same
`(judge_id, query_id, doc_key)` overwrites rather than duplicating — deliberately, so a
retry after a dropped connection cannot inflate one judge's contribution. The same property
means a judge that drifts, mistypes, or is talked into a different name either fragments its
own label set or **overwrites another judge's**. The number R.4 exists to produce degrades
and nothing in the logs looks wrong. Same shape as the confused deputy one layer down:
every component behaved correctly.

**Why fix it before it is a security problem.** The day a second annotator is a person
rather than a model, identity-as-parameter is a real boundary, and the fix is the one R.5c
needs anyway: derive the principal from the token, treat any identity the model can type as
untrusted. Doing it now is cheap; doing it after a human annotator exists means migrating
labels whose ownership is already ambiguous.

**The agent case is worse than the ordinary API case.** With a normal endpoint an attacker
crafts the request. Here the field is filled by a model that can be argued with, so prompt
injection reduces the cost of impersonation to one persuasive sentence — and S.1/S.2 exist
precisely because the corpus is a channel an attacker can write to.

**A second instance, found at the same time and since fixed.** `/api/ask` and `/api/ask/news`
accept `userId` as a request-body field **defaulting to `"local-user"`**, and it was written
through to `spec["owner"]` on the generated strategy spec — so the ownership of a created
artifact was self-declared by the caller, with a default that succeeded silently when nobody
set it. **`quant_api` now takes the owner from the token instead** (R.5c). The field still
exists on the quant_ai request model, but the API no longer trusts it, so what remains is
removing a parameter that no longer does anything.

**`judge_id` is the case that is still open**, and the rule covers both — **business arguments
narrow *what*, the token decides *who*.** A signature or request body carrying `user_id`,
`tenant_id`, `judge_id` or `owner` has moved authorization into the payload.

**Interim mitigation, without waiting for OBO.** Reject a `judge_id` that does not match the
authenticated principal once one exists. Until then, make the write **reject rather than
overwrite** when `(query_id, doc_key)` already carries a different judge — that preserves the
retry-safety the overwrite was built for while removing the cross-judge destruction case.

### R.5 Authentication and authorization, phases 1 and 2 (2026-08-03)

**The finding.** `SecurityConfig` ended with `.anyRequest().permitAll()`. Three path
patterns required a token; everything else was open, including
`/api/portfolio/holdings`, which served personal financial data unauthenticated. The JWT
infrastructure was configured and enforcing almost nothing — the worst of the two states,
because it reads as protected. Measured before: `GET /api/portfolio/holdings` with no
token returned **200**. After: **401**.

**The order of work is the design.** quant_ai sent no credential at all and six of eight
UI modules sent none either, so tightening the server first would have broken every page
and every MCP tool simultaneously. Phase 1 made both carry a token while the server still
permitted everything; phase 2 flipped the default. Adding the credential before requiring
it is the only sequence with no broken window in the middle.

| principal | read | write |
|---|---|---|
| no token | 401 | 401 |
| `quant-ai` service account | 200 | **403** |
| `user` / `admin` | 200 | 200 |

**Why read and write are split.** quant_ai holds a service-account credential broader than
any single user's — the confused deputy. It cannot be removed until on-behalf-of exchange
lands (R.5c), but its blast radius can be: the service account has `quant-read` and not
`quant-write`, so an injected agent can read the platform and **cannot record a trade**.

**`KeycloakRealmRoleConverter` is not boilerplate.** Spring's default converter reads
`scope`; Keycloak puts realm roles under `realm_access.roles`. Without the converter the
roles are in the token, invisible to the rules, and every `hasRole` fails closed — which
looks exactly like a permissions bug.

#### Three mistakes worth keeping, because each was caught by a different kind of evidence

1. **Granting write to the service account.** The first role assignment put `quant-write`
   into `default-roles-quant`, which service accounts also hold — handing the agent the
   exact capability the split exists to deny. The admin API returned `204` three times.
   Caught by **decoding the issued token**. *Role assignment is not confirmed by the API
   accepting it; it is confirmed by the claim appearing in a token.*

2. **Shipping a UI that could not authenticate.** The phase 1 UI change was committed and
   never built into an image, so the browser ran a bundle with no `Authorization` header
   against an API that had just started requiring one. Every page failed. This is the
   drift documented one section below, repeated on the next service within the hour.
   Caught by **the error text**: `Failed to fetch signals` is the pre-migration string, so
   the message itself proved the old bundle was running.

3. **Read granted to no human.** `quant-read` lived only in `default-roles-quant`, and the
   `admin` user was never assigned that composite — only the `admin` role. Service
   accounts get the default composite automatically, so quant_ai worked and every human
   got 403. API-level testing missed it entirely because the one principal it exercised
   was the only unaffected one. Caught by **the user opening the browser**. The listing
   `admin -> ['quant-write']` had already been printed and read past.

The through-line: each layer needs evidence from that layer. A 204 is not a token, a
commit is not a deployment, and a passing API test is not a working UI.

---

## K. Architecture & Language Decisions (决策记录)

记录已评估但主动排除的技术选型，避免未来重复讨论。

### K.1 不引入 Go / C / C++ (决策日期: 2026-07-16)

**结论**: 当前及可预见的未来不需要用 Go、C 或 C++ 替换任何现有服务。

**理由:**

| 潜在场景 | 实际瓶颈 | 结论 |
|---------|---------|------|
| GDELT 下载 / 新闻采集 | 网络 I/O，带宽限制 | Python 足够；换语言无收益 |
| LLM 推理 (Gemma / Qwen) | GPU/CPU 推理内核 | LM Studio 底层已是 C++；无需重写 |
| 特征工程 (pandas) | 内存操作，100 symbols × 189K rows | Python + numpy 足够；算法优化比语言切换收益高 |
| REST API (quant_api) | 内部服务，并发量低 | Java Spring Boot 完全足够 |
| 信号评分 / 回测 | 每日单次运行，秒级耗时 | 无延迟要求 |

**核心原因**: 策略持仓周期 5–60 天，信号只需每天 08:30 计算一次，延迟要求是**分钟级**，不是毫秒级。需要 C/C++ 的场景是 HFT（微秒级订单路由、tick 级订单簿），与本项目场景差三个数量级。

**唯一的例外条件**: 若未来升级为高频/盘中策略，需处理每秒千条以上 tick 数据，可考虑用 **Go** 编写 tick processor（goroutine 并发模型适合 WebSocket 流处理）。当前 J.5 盘中止损监控用 Python asyncio 足够。

**现有技术栈不替换的理由:**
- Python: data/ML pipeline 生态无可替代（pandas/LightGBM/LM Studio SDK）
- Java Spring Boot: REST API 生产级可用，团队已有代码资产
- React/TypeScript: 前端无替代方案

---

## Q. Market Briefs and Event-Driven Decisions (2026-10-22)

**Why this series.** On 2026-10-21 Lam Research guided below hopes after the US close; the next
day Tokyo Electron fell 7%, SK hynix 5%, ASML 3% and the user's semiconductor holdings 3-5% in
pre-market, alongside Brent at $112 on Middle East escalation. The question asked: *does the
platform capture events like this — an earnings miss, a war, an oil shock — and do they drive
decisions?* The audit below says: per-company news sentiment, yes; propagation, macro and
geopolitics, no; and right now nothing at all, because the pipeline is down.

### Q.0 Done on 2026-10-22 (quant_ai, quant_ui, quant_docker)

- **Portfolio moved into quant_ai** (`markets/portfolio.py`, from job_agent's dashboard): trades,
  average cost and FIFO, Nasdaq quotes incl. pre-market / after hours, watchlist, charts. Host
  process, SQLite under `~/Library/Application Support/quant_ai`, Drive backup; launchd keeps
  it alive. Sale profits are pushed to job_agent's budget through an idempotent endpoint.
- **Global markets**: 16 Asian / European exchanges by region -> country -> exchange (CNBC,
  Korean stocks via Naver) and a macro board (Brent/WTI, gold, US indices and futures, VIX,
  yields, FX).
- **Briefs** written by `claude -p` on the user's subscription, Chinese + English, from a
  snapshot of the numbers plus cited web search:
  - summaries: Asia & Europe 14:00 Dublin; US after 20:05 New York;
  - **week ahead** 13:30 Dublin: earnings of holdings / watchlist / 17 sector bellwethers over
    5 trading days (Nasdaq calendar, consensus EPS, implied move from the ATM straddle), main
    economic releases, beat / miss scenarios per holding;
  - **flash**: a bellwether moving >=5% pre-market / after hours triggers a transmission
    analysis (Asia, Europe, the holdings at the next open). Once per company per day, cap 4.
- **Scored predictions**: every brief ends with checkable calls ("8035.T closes <= -3% on
  10/23", stated confidence). Only symbols the brief was shown, only sessions not yet open when
  it was written (a flash at 14:43 Dublin predicting that day's US close was half known — fixed
  the same day). Scored from CNBC daily bars after the close; scorecard = hit rate, Brier score,
  calibration by confidence bucket, per brief kind.
- quant_ui: My Holdings rebuilt on these routes; Market Briefs tab with the scorecard.
  quant_docker: `ui_only.sh` (since replaced by `scripts/core.sh`) starts just the login chain (mysql, mongodb, keycloak, kafka,
  quant_api, quant_ui); everything else `unless-stopped`.

### Q.1 Audit: what the signal pipeline does with events today

| Capability | State |
|---|---|
| Per-company news: sentiment, 7 event types, signal strength (Gemma + Qwen labels, ~868K matched articles) | ✅ features `avg_sentiment_5d`, `sentiment_shift_5d`, `news_burst_20d`, `earnings_beat/miss_signal`, `ah_gap` |
| Market regime | ✅ VIX, 10y, DXY, SPY -> RISK_ON / NEUTRAL / STRESSED / RISK_OFF reweighting |
| **Propagation** (Lam's guidance -> Tokyo Electron, ASML, SK hynix) | ❌ news only moves the symbol it names; `sector` is used only for sector-relative ranks in training. Planned as the **N series** (N.1-N.5 pending) |
| **Macro / geopolitical news** (war, OPEC, oil) | ❌ `event_type = macro` is labelled but feeds no feature; no oil series anywhere in quant_data; GDELT is a news source only, its tone / conflict fields unused. Only indirect, via VIX, and only as down-weighting, never direction |
| **Earnings vs expectations** | ⚠️ "beat" is inferred from news sentiment, not actual vs consensus; no forward calendar (F.14 pending) |
| **Coverage** | ❌ US universe only; no Asian / European listings |
| **Latency** | ❌ one batch at 07:30: an after-hours report enters features the next morning, after Asia has traded it |
| **Pipeline running** | ❌ signals stop at 2026-07-17, features 2026-10-09, macro 2026-10-14. The host Airflow scheduler (`com.quant.airflow-scheduler`) crash-loops on `connection refused 127.0.0.1:25432`: its metadata DB is the `airflow-postgres` container, so whenever Docker is off nothing is collected |

### Q.2 Revive the pipeline — prerequisite for everything below (🔴, 1 day)

- [x] ~~Move the Airflow metadata DB off Docker~~ — not enough on its own: the data itself
      (MongoDB, MySQL batch queue, Qdrant) lives in Docker too. Decision (2026-10-22): Docker stays
      up with `quant_docker/scripts/core.sh` (login chain + airflow-postgres, qdrant, mlflow; restart always).
- [x] **Root cause of the stale signals found**: not only Docker. Since the 2026-07-21 reorganisation
      the price and analyst collectors loaded a non-existent `.env` path, failed every run, and blocked
      `score_signals`. Fixed (f97dc75); `daily_signal_pipeline` ran green end to end on 2026-10-22 and
      signals moved from 2026-07-17 to 2026-10-22.
- [x] Catch-up started 2026-10-22: GDELT backfill of 2026-10-08 → today, then match / enrich / features.
- [x] Alerts: per-task failure notification (`notify_failure`) + freshness watchdog in quant_ai
      (`/api/markets/pipeline/health`, widget line, one notification a day while stale).
- [x] LM Studio kept (verified that mlx-lm reproduces gemma but not qwen3.5, and that llama.cpp
      embeddings drift enough to need a reindex — see below); its server is kept up headless by
      launchd `com.quant.lmstudio-server` so the 03:00 news chain does not depend on the app being open.
- [x] Caught up 2026-10-24 after the disk-full pause of 10-22 (backfill DAGs paused, a hung orphan
      collector killed): company match 10-11 → 10-24, enrich passes A/B (3,005 articles, 0 errors),
      features and the Qdrant index; `/api/markets/pipeline/health` all green.
- [x] **One LM Studio task at a time, sized to the machine** (`quant_data/tools/lm_session.py`).
      Two LLM tasks at once made LM Studio swap models on every request (10-23: 69/76 job_agent judge
      calls failed; 10-24: ~70 Channel Errors when backfill_1 and backfill_2 overlapped), and every
      model ran with one parallel slot, so 8 client workers queued behind one prediction (0.8 art/s).
      Each LLM task now goes through a shared flock (job_agent's own `lm_model_guard.py` honours the
      same lock), unloads the LLMs it does not need, loads its model with the slot count measured on
      this machine, sets its worker variable to match and unloads afterwards unless a queued task needs
      the model. Measured on the M5 Pro 48 GB (generated tok/s at 1/2/4/8 slots):
      gemma-4-e4b 50 / 86 / 137 / 155 → 8 slots; qwen3.5-9b 52 / 80 / 113 / 120 → 4 slots;
      two qwen3.5-9b instances × 2 slots 82, below one × 4 — one instance with more slots wins on one GPU.
- [ ] Confirm one fully automatic night (02:00 UTC backfill chain + 07:30 signals) with no alert,
      the first one through `lm_session` (qwen3.5-4b calibrates itself at the start of gdelt_collect).

**LM Studio replacement, evaluated 2026-10-22 (not done, kept as an option).** Python MLX can load
every model without LM Studio (mlx-lm 0.32 supports qwen3_5 and gemma4). Against LM Studio on the
same files and the pipeline's own `call_llm`: gemma pass A matches (event type 99%, sentiment
corr 0.988 vs stored labels); qwen3.5-9b pass B does **not** (corr 0.78-0.80 vs LM Studio, whose
own repeat is 0.999; four prompt renderings and mlx-vlm tried) — LM Studio's MLX engine is its own
native build. nomic embeddings via llama.cpp on the same GGUF: cosine 0.9965, top-10 overlap 8.9/10.
Switching would need a reindex, R.4 re-run, pass-B re-labelling with an IC check, and the qwen27
judge's kappa re-measured.

### Q.3 Events as structured features (🟡, ~6 days; feeds N.4)

- [ ] **Peer / supply-chain graph** (= N.1 + N.3, extended): curated edges for the semiconductor
      chain first (equipment -> foundry / memory -> chip designers -> hyperscalers), including
      non-US names (Tokyo Electron, ASML, Samsung, SK hynix). A company event propagates one hop
      with a signed weight. Cross-check curated edges against return co-movement.
- [ ] **Oil and geopolitical risk index** from the GDELT GKG columnar store (Stage 6B): daily
      tone and conflict-theme intensity for the Middle East / Russia-Ukraine / Taiwan Strait, plus
      Brent and WTI added to `macro_indicators`. Features: level, 5-day change, shock flag.
- [ ] **Earnings surprise, measured**: actual EPS / revenue vs consensus and the post-report gap
      (Nasdaq calendar gives the consensus; F.14 covers the pre-report probability).
- [ ] **Intraday path for after-hours events**: a small evening job (or the flash trigger) that
      writes the event and the propagated scores the same night, so Asia-session decisions can use it.
- [ ] Optional: Asian / European symbols in the feature universe (prices are already collected
      for the briefs).

### Q.4 Promote LLM event calls to a factor only after they earn it (🟡, gate, then 2 days)

The briefs' predictions are a running out-of-sample test of "can an LLM read an event's impact".
Wire them into `score_daily_signals` only when the scorecard says so:
- [ ] at least 60 scored calls, spread over at least 4 weeks and several event types;
- [ ] hit rate above the base rate of the same claims (e.g. how often `|move| >= 2%` happens anyway);
- [ ] Brier score below 0.22 and calibration within +-10 points per confidence bucket;
- [ ] then a walk-forward backtest with the call as one factor (H.1 realism rules), compared
      with the same model without it. If any step fails, the calls stay a reading aid.

**Interview angle.** Same discipline as R.4 (judge validated before used): an LLM that explains
every move after the fact is easy; one whose stated confidence matches how often it is right,
measured on calls made before the fact, is the claim worth making.

### Q.5 Holdings advisor — event-driven advice on the user's own positions (🔴, ~3 days)

**Goal (user, 2026-10-25).** The user's priority is profit: get the losing positions back (INTC is
-18%) and grow. The system watches the holdings and, when something worth reacting to happens,
writes a report with concrete actions: what to do, at what limit price, how much, until when, and
what happens if it is wrong — e.g. trim into strength before INTC's 10-29 earnings and buy back
lower after, to lower the cost basis. Advice only: nothing is ever traded automatically.

**Data (all already in the platform).** Holdings, cost and weights (quant_ai), live quotes with
pre/post (Nasdaq, 5 s), daily bars (support / resistance / ATR), earnings calendar with consensus
EPS and the options-implied move (Nasdaq), news per company with LLM sentiment and event type
(quant_data, intraday every 30 min, labels overnight), the quant model's ranks and LONG list
(daily), the macro board. New: **available cash**, entered by hand in My Holdings (starts at 0).

**Monitoring — every 15 minutes, code only, no model.**
- Price move beyond the stock's own threshold: **2x its median absolute daily move over the last six
  months**, recomputed daily. A fixed 3% was measured first and rejected: INTC, SK hynix, Seagate and
  WDC moved more than 3% on 50-57% of days; at 2x median (INTC/SKHY/STX ~6%, TSM ~3%) each name
  triggers about once a week.
- Price reaching a limit from an open recommendation.
- Earnings: a holding reports tomorrow (prepare a plan), or has just reported (read it, adjust).
- Important news on a holding: earnings / guidance / rating or target change / M&A / buyback /
  regulation / litigation / export controls / management change (keyword rules first; a local
  model to rank intraday headlines only if the rules prove too coarse), or a burst of news.
- A sector bellwether moving 5%+ outside regular hours (the existing flash trigger).
Cooldown: one trigger per holding and event type per 2 hours; at most ~6 updates a day.

**Flow.** trigger → snapshot built by code (position, break-even, % needed to get back to cost,
support / resistance, ATR, earnings and implied move, 7 days of news, quant rank, buy candidates
from the LONG list, cash) with **candidate limit prices computed by code** (implied move when a
report is near, else 2x ATR), so the model quotes numbers rather than inventing them → Claude
(`claude -p`, subscription, web search) writes the report in Chinese and English → a structured
ORDERS block (symbol, side, % of position or shares, limit, valid until, reasons), validated by code
(held or candidate symbol, limit within range of the price, validity at most 30 days) → stored and
shown in My Holdings → scored by code: filled or not from daily bars, and at expiry whether acting
beat not acting.

**Reports.** A full report every weekday at 13:00 Dublin (in the US pre-market, 1.5 h before the
open); focused updates when a trigger fires. Sections: bottom line (the 2-3 actions today, or why
nothing); each holding (status, drivers with sources, orders, the failure case); earnings plays
(pre/post plan from the implied move, partial size, the gap risk of selling before a jump); new
ideas (1-3 from the LONG list, preferring names that reduce the chip / memory concentration, sized
to the cash or as a switch when cash is 0); risks and rules (concentration; the Irish CGT four-week
rule on a loss sale bought back within four weeks).

**Alerts.** Two levels. Urgent — results just out, a recommended limit reached, a move beyond 1.5x
the threshold, major news (M&A, regulator, profit warning): a macOS notification and a red banner
in My Holdings. Normal — everything else: a "new advice" mark in My Holdings only. No widget lines
and no phone push for now.

**Models.** Monitoring, levels, validation and scoring: code. Analysis and writing: Claude, because
it needs reasoning and fresh news (the local qwen agreed with Claude at kappa 0.43 in R.11 and is
slow with thinking). Quota: ~1 report on a quiet day, 3-6 on an earnings day, 3-5 min each.

- [x] Cash in My Holdings (stored with the portfolio, editable, starts at 0)
- [x] `markets/advisor.py`: snapshot, thresholds, levels, triggers, orders, scoring
- [x] `advisor` brief kind: schedule 13:00 Dublin, focused updates, ORDERS block, urgent alerts
- [x] My Holdings: latest report, open orders with fill status, history and scorecard
- [x] Tests; one live report end to end (v1, 2026-10-25)

**v2: plans generated and tested by code, chosen by the model (2026-10-25).** The user's verdict on
v1: "太不智能了". Its first report proposed trimming INTC 20% at $91.26 before earnings and buying
back at $78.35, which was the user's own idea read back from the conversation, sized in fractional
shares a broker cannot fill, below the average cost, with no evidence that it beats holding. In v2:

- *Candidates in code* (`markets/strategy.py`), whole shares: hold; one T (sell part at +a, buy the
  same shares back at -b, the buy-back active only once the sale filled) at three widths; a two-step
  ladder; trims; a sale at the average cost when within reach; an add when there is cash. Widths are
  in units of the move scale: the options-implied move when the stock reports within the horizon,
  else 2 x ATR(14).
- *Tested on the stock's own past*: around each of its last 16 reports (daily bars from 5 sessions
  before to 10 after, `earnings_reactions` in Mongo, refreshed weekly by `weekly_model_training`;
  SK hynix from its Seoul listing 000660.KS, the ADR having listed on 2026-07-10), entered as many
  sessions before the reaction as today is, limits scaled to that history's typical move; else
  rolling 15-session windows of the last year. Result: gain against holding, win rate, P10, fill
  rate per leg, regret (sold, never bought back, ended higher).
- *Simulated for this time*: 3,000 paths with the stock's daily volatility and, on the reaction
  day, a past reaction (centred) scaled to the implied move: how likely each limit fills.
- *Profit first, enforced in code*: a plan is offered only when it beat holding on that history
  (n >= 8, mean > +0.05% of the position, wins >= losses) and never sells below the average cost
  without a buy-back. The model picks a candidate id per holding in a PLANS block (or none) and
  explains it; code turns the plan into its orders. The ORDERS block is left for new buys only,
  rounded down to whole shares.
- *Conditional orders*: `advice_orders.parent_id`; a buy-back is `waiting` until its sale fills,
  counts only from the next session, and is `void` if the sale never fills.

First result (2026-10-25, last 16 reports each): every pre-earnings sale or T on INTC, SKHY and STX
trailed holding (-0.3% to -1.3% of the position on average); holding through the report returned
+4.6% to +7.2% on average, up 56-75% of the time, and the 10 sessions after the reaction drifted up
after both up and down reactions (INTC +8.3% / +1.1%). So the advice for this week's reports is to
hold, with the numbers. TSM (no report in the horizon) has small eligible T plans (+0.12 to +0.16%).

- [x] `strategy.py`, `earnings_reactions.py`, PLANS block, conditional orders, UI ("after #X fills")
- [ ] After the reports: compare the advice with what happened (scorecard) and widen the candidate
      set if a family keeps winning (post-reaction entries, adds after a drop once there is cash)

**v3: an earnings-day trading policy learned from data, not written by hand (user, 2026-10-25).**
The user's idea: sell into the earnings-day pulse and buy back lower. A hand test on daily bars
(sell at the open after a gap up, buy back 2% lower or at the close) said +1%/share for INTC
(7/9) and -1.4% for STX (shares keep running after a gap up), but daily bars cannot tell whether
the high came before the low, and a rule per stock is exactly what the user does not want: "我想让
ML或者AI自动学会这个策略".
- *Data*: hourly bars with pre/after-hours (yfinance, back to 2023-11) around every report of the
  whole universe (~100 stocks, ~11 reports each), EPS estimate / reported / surprise, daily bars.
  Minute bars (Alpaca, from 2016) when a key is available.
- *Actions*, enumerated by code: hold; sell at the open or at +a% and buy back at -b% or at the
  close of day 1 / day 3; buy at the open or -b% (when there is cash). Label = what each action
  made per share against holding.
- *Features*, all known at the open of the reaction day: gap, the pre-market path, EPS surprise,
  run-up, volatility, gap relative to the stock's typical reaction, the stock's own past fades
  (earlier reports only), the market's gap, report timing.
- *Model*: LightGBM over (event, action) rows; policy = the action with the highest predicted gain
  when it clears a margin, else hold. Walk-forward by quarter; offered only if it beats holding
  and a static rule out of sample.
- [x] Data and labels  - [x] Walk-forward model and report  - [ ] Live (only once it beats holding)

*First result (2026-10-25): no learnable edge.* 1,120 reports of 101 stocks (2023-11 .. 2026-10),
30 actions, walk-forward by quarter over 806 out-of-sample reports
(`research/models/earnings_policy.py`):

| Decision point and features | rank IC (pred vs outcome, per action) | Policy when it acts |
|---|---|---|
| Open: gap, pre-market path, EPS surprise, run-up, volatility, the stock's past fades, market | -0.001 to +0.019 | -0.3% to -0.5% per share, win 59-66%, P10 -7.5% |
| + the platform's news sentiment published between the report and the open | +0.002 / +0.014 | -0.3% to -0.7% |
| 10:30, + the first hour's path | +0.007 | -0.1% to +0.2% (noise) |

High win rates with a negative mean: small gains on fades, wiped out by the reports where the stock
keeps running and the shares are bought back higher. Post-report news sentiment correlates with the
gap (Spearman 0.34) but not with the open-to-close move (0.008): it is priced in at the open. The
"INTC fades +1%/share" seen on daily bars (9 reports) does not survive 1,120. Hindsight-best would
make +4% per report: the money is there, nothing available at the open predicts which way.
Next levers, in order: minute bars from 2016 (Alpaca, ~3x the reports); the call transcript read by
an LLM (guidance, tone) as a feature. Until a version beats holding out of sample the advisor keeps
holding through reports.

*Second round (2026-10-25 evening): more data and the release read by an LLM.* Alpaca 5-minute bars
incl. pre/after-hours from 2016: 3,866 reports. The press release behind each (EDGAR 8-K item 2.02 /
6-K, accepted before the open: 3,747 found, 97%) read by local qwen3.5-9b (`earnings_releases.py`):
full-year outlook raised / kept / lowered, margin direction, tone, revenue against the last outlook,
next quarter's outlook against this quarter, capital return, restructuring. Walk-forward over 3,030
out-of-sample reports: rank IC rose from ~0 to +0.05 with the larger sample and to +0.056/+0.059 with
the release features (27 of 30 actions positive), still too weak for a policy that makes money
(mean about 0 per share when it acts). The release is mostly priced in at the open: its fields
correlate with the gap (0.13-0.25) and hardly with the open-to-close move (-0.08..+0.03).
One pattern worth following: after a full-year outlook cut the stock gaps down (-2.7% on average)
and then recovers. Buying at the open and holding three sessions: +0.30% (n=77, not significant) in
2016-2020, +2.46% (n=67, 4 standard errors) in 2021-2026; selling at the open the same day lost
-1.39% in 2021-2026. Not stable across periods and one of many looks, so not a rule yet; for a
holder it argues against selling into the open after a guidance cut. Next: a 1D-CNN on the 5-minute
pre-market / first-hour path as a challenger to LightGBM; earnings spillover (a peer's report as the
event for the holdings, more bets per year); an LLM proposing hypotheses for the same event engine,
with a multiple-testing correction.

**v4: the after-the-close pulse, from 1-minute bars (2026-10-25 night).** The user's actual idea was
not the next day: right after an after-the-close release the stock spikes for minutes and often
fades before or during the call; sell a ladder into the spike, buy the shares back lower. INTC
2026-07-23: +8.6% at 16:00, +11.8% at 16:20-16:25, +4.1% by 17:15 (2026-04-23: +16.7% and kept
rising). `research/models/earnings_pulse.py`: Alpaca 1-minute bars 15:30 .. next day 10:30 for 2,491
after-the-close reports since 2016; the release minute found in the bars (the wire beats the SEC
acceptance by minutes: INTC moved at 16:00-16:01, accepted 16:09), the call time read from the
release (82%). 224 plans enumerated: when the ladder goes in (before the release; 1/3/5/10/20/30
minutes after it; 5 minutes before the call) x levels (+1/2/3 .. +5/8/12%) x buy-back (5 or 30
minutes into the call, end of after-hours, next open, or 1/2/3% under each sale).

| Walk-forward 2019-2026 (each year trained on the earlier ones) | Acted | Mean when acting | Win | P10 |
|---|---|---|---|---|
| Per stock, the plan that did best in its earlier years | 96% | +0.05% (se 0.08) | 44% | -2.0% |
| Conditional LightGBM (move since the close at placement, its range and volume, run-up, the stock's own past on the plan, EPS surprise and the LLM-read outlook after the release), 0.10%/side | 42% | +0.49% (se 0.12) | 66% | -1.9% |
| Same, 0.25%/side and limits must trade through by 0.05% | 30% | +0.66% (se 0.13) | 59% | -1.15% |

Every year >= 0 in the strict run (2019 -0.02% .. 2024 +0.67%). INTC: 14 of 30 reports, +1.33% per
share of the ladder, 79% wins; STX negative (7 reports, -1.29%: it keeps running), so mostly
left alone. Worst single case -15%: a ladder on part of the position, never all of it.
Pre-release plans get no post-release features (the first run leaked them: +0.54% -> +0.49%).
- [ ] Live for the holdings: at the release, features from live quotes + EDGAR + the LLM read, the
      model's plan as whole-share extended-hours limit orders in an urgent advisor update; the
      broker must accept extended-hours limit orders
- [ ] Final model on all data, refreshed weekly; scorecard of live calls against the replay

---

## Consolidated Priority Table (all pending items)

**Top of the queue, as of 2026-07-30.** The R-series is ranked above everything else pending
because it is the only block addressing named, sourced interview feedback (eBay, 2026-07-28:
"more experience with AI at scale, particularly RAG and MCP"), and because the corpus that
makes it credible — 845K articles — is already collected and sitting unindexed. R.4 carries
the weight: it turns retrieval into numbers.

| Priority | Item | Interview Value | Practical Value | Effort | Status |
|---|---|---|---|---|---|
| 🔥 | **Q.2 Revive the data pipeline** | DE: an outage found and fixed | 🔴 Nothing is fresh without it | 1 day | 🟡 2026-10-24: caught up (company match current, health all green); LM Studio tasks serialised and sized by `lm_session`; confirm one automatic night |
| ⭐⭐⭐ | **Q.3 Events as structured features** (peer graph, oil / geopolitical index, earnings vs consensus, same-night path) | Quant+AI | 🔴 Lam / war / oil reach the signals | ~6 days | [ ] Pending (with N.1-N.4) |
| 🔥 | **Q.5 Holdings advisor (event-driven advice with limit prices, scored)** | AI agent on real decisions, with a track record | 🔴 The user's own positions | ~3 days | 🟡 In progress (2026-10-25) |
| ⭐⭐ | **Q.4 LLM event calls → factor, behind a gate** | 🔴 LLM-forecast evaluation | High | gate + 2 days | [ ] Collecting scores (briefs' predictions since 2026-10-22) |
| 🔥 | **R.1 Qdrant + embedding pipeline over 845K news** | 🔴 AI at scale — the corpus exists, unindexed | High | 3 days | ✅ Done (2026-07-30) — 716,074 vectors in 2.65h; on_disk vectors cut memory 4.3x; index repaired in place twice (13,027 dupe points, null event_type) without re-embedding |
| 🔥 | **R.2 Hybrid retrieval (Mongo weighted text + dense, RRF)** | 🔴 The answer most candidates cannot give | High | 1.5 days | ✅ Done (2026-08-01) — **and naive RRF measurably loses to both single legs**; parameters left for R.4 to settle rather than tuned by eye |
| 🔥 | **R.4 Retrieval eval harness (recall@k / MRR / nDCG ablation)** | 🔴 "Depth" means a table, not a longer component list | Medium | 2 days | 🟡 Judge validated (2026-10-09): v1 kappa **0.41** vs 150 reference labels, rubric v2 **0.74** (0.67 in the full re-judge). The "93% = inflation" reading was wrong — ~91% of the pool is genuinely related; the loose bar was the problem. Table: **dense 0.803 ≈ hybrid_k60 0.797 nDCG@10 (CI includes 0), both > sparse 0.683 (significant)**; P@10 (g=2) added. Open: human spot-check of the reference labels |
| 🔥 | **R.10 Retriever wired into generation (`/api/ask/news`)** | 🔴 Without it "I built RAG" is only the R | Medium | 1 day | ✅ Done (2026-08-01) — citations by id, refusal on empty retrieval, symmetric date filters |
| ⭐⭐⭐ | **R.11 Generation eval (faithfulness / citation accuracy)** | 🔴 recall@k says nothing about whether the answer is true | Medium | 2 days | ✅ Done 2026-10-24 — thinking off: ~10x faster, faithfulness 0.869 vs 0.899 (n.s.); judge's evidence 2,996/2,996 verbatim |
| ⭐⭐⭐ | **R.12 One retriever for every news consumer (`search_news` hybrid mode)** | 🔴 The research agent gets the same retrieval as `/api/ask/news` | High | 1 day + R.4 | ✅ Done 2026-10-09 — hybrid default (+0.114 nDCG@10 over keyword, from R.4), fusion only in quant_ai, Java calls `/api/retrieve/news`, reported fallback; keyword leg is 95% of the ~0.9 s latency |
| ⭐⭐⭐ | **R.13 One agent for every stock question (agent picks the tools)** | 🔴 Agentic RAG: the model decides when to retrieve and which tool to trust | High: one place to ask anything | ~2 days | [ ] Pending (2026-10-25) — signals/performance tools answer 401; agent lacks the quant_ai tools; thinking still on per step |
| ⭐⭐⭐ | **R.3 Cross-encoder reranking** | AI essential | Medium | 1.5 days | ✅ Done (2026-10-13) — nDCG +0.076 [+0.043, +0.113] for the shipped top-30/256 config (~1 s), +0.117 at top-100; significant under both validated judges; behind NEWS_RERANK in /api/ask/news |
| ⭐⭐⭐ | **R.6 MCP protocol depth (resources / prompts / sampling / elicitation)** | 🔴 Everything past `@mcp.tool()` | Medium | 3 days | [ ] Pending |
| ⭐⭐ | **R.8 Scale concerns (embed cache, reindex, p99 latency, cost/query)** | AI production credibility | Medium | 2 days | [ ] Pending |
| ⭐⭐ | **R.7 RAG as a feature source (grounded event extraction → features)** | AI+Quant crossover | High | 3 days | [ ] Pending (after R.2, N.1) |
| ⭐⭐⭐ | **H.1 Backtest with transaction costs + liquidity filter** | Quant essential | 🔴 Real returns | 2 days | ✅ Done — COMMISSION_BPS=5, SLIPPAGE 10/30bps tiered, MIN_DOLLAR_VOL=$5M filter in backtest_portfolio.py |
| ⭐⭐⭐ | H.2 Market Regime detection (VIX filter) | Quant essential | 🔴 IC stability | 4 days | ✅ Done (2026-07-15) — 4-regime weight switching (RISK_ON/NEUTRAL/STRESSED/RISK_OFF) |
| ⭐⭐⭐ | H.3 Paper Trading engine + stop-loss | Quant essential | 🔴 OOS validation | 4 days | ✅ Done (2026-07-15) — vol-adaptive stop-loss (2×vol_20d) + OOS IC rolling monitor |
| ⭐⭐⭐ | Stage 7 Airflow + Kafka end-to-end | DE critical | High | 1 week | 🟡 Revived 2026-10-22 — the host Airflow scheduler (launchd) runs all 10 DAGs; its metadata DB and the data are in Docker, so `core.sh` must be up. Kafka runs (quant_api needs it). See Q.2 |
| ⭐⭐⭐ | G.1 Live trading execution (Alpaca API) | Quant/Prod | 🔴 Real money | 2-3 weeks | [ ] Pending — paper trading done; need broker API + order manager + risk guardrails |
| ⭐ | G.2 Stock universe expansion (103→150+) | Quant bonus | Medium | 2-7 days | Phase 1 ✅ Done (STX/WDC/HXSCL added 2026-07-15); Phase 2 energy/materials [ ] Pending |
| ⭐⭐⭐ | C.2 Risk metrics (Sharpe / drawdown) | Quant essential | High | - | ✅ Done |
| ⭐⭐⭐ | C.9 Factor analysis report (IC/IR/SHAP) | Quant essential | Medium | - | ✅ Done |
| ⭐⭐⭐ | C.8 ETL unit tests | DE essential | Medium | 3 days | ✅ Done (2026-07-15) — 90 tests passing; scoring 60%, positions 52%, features 40% cov |
| ⭐⭐⭐ | E.7 README + architecture diagram | All interviews | Medium | 1 day | ✅ Done (2026-07-15) |
| ⭐⭐⭐ | Stage 7 MLflow actual runs | DE/MLE | Medium | 1 day | ✅ Done (2026-07-15) — 8 runs logged (Ridge/LightGBM/Ensemble × 20d+60d) |
| ⭐⭐ | H.4 Signal quality monitoring (rolling IC) | Quant strong | 🟡 Signal health | 2 days | [ ] Pending |
| ⭐⭐ | C.1 Daily signal automation | Medium | Extremely high | 3 days | ⚠️ Was silently broken 2026-07-21 → 2026-10-22: after the collectors reorganisation (d14f30c) the price and analyst collectors read a stale `news_collectors/finnhub/.env` path, failed every morning, and `score_signals` (downstream) never ran — signals stuck at 2026-07-17. Fixed 2026-10-22 (f97dc75); runs under Airflow |
| ⭐⭐ | C.3 Signal UI page | Medium | Extremely high | 3 days | ✅ Done |
| ⭐⭐⭐ | **J.2 Daily SLM company match for realtime news** (Finnhub/NewsAPI/Yahoo → symbol field → 情绪特征) | DE关键 | 🔴 填补数据缺口 | 1.5 days | ✅ Done 2026-10-08 (6B.6a) — `backfill_1_collect_and_match` (02:00 UTC) matches every new `news_articles` doc, intraday sources included (N.0 gave them candidate symbols) |
| ⭐⭐⭐ | **J.4 Pipeline failure alert** (Slack webhook on任意任务失败) | DE essential | 🔴 运维必需 | 0.5 days | ✅ Done 2026-10-22 — `notify_failure` on every task (macOS notification + `airflow_task_failures.log`) and quant_ai's freshness watchdog (`markets/pipeline_health.py`, every 30 min, widget warning) for when nothing runs at all |
| ⭐⭐⭐ | I.1 quant_mcp_server (signals/news/positions/backtest as MCP tools) | AI差异化 | 极高 | 3 days | ✅ Done — 10 read-only tools over stdio; depth gaps now tracked as R.6 |
| ⭐⭐⭐ | I.2 Claude Desktop integration (quant MCP → Claude对话查信号) | AI差异化 | 高 | 0.5 days | ✅ Done — verified over the real MCP protocol |
| ⭐⭐ | F.2 RAG news search UI (search box over the R.2 retriever) | AI essential | High | 1 day | [ ] Pending — retrieval superseded by R.1–R.3; "Qdrant already deployed" was never true |
| ⭐⭐ | F.3 SHAP interpretability | MLE strong | Medium | 1 day | ✅ Done (factor_analysis.py) |
| ⭐⭐ | **J.3 Daily LLM sentiment enrichment** (每日Gemma+Qwen对新文章打分，保持情绪特征最新) | MLE+DE | 高 | 1.5 days | ✅ Done 2026-10-08 (6B.6a) — `backfill_2_enrich_and_features` (pass A gemma, pass B qwen3.5-9b, merge, features, Qdrant index) is triggered daily by backfill_1 |
| ⭐⭐ | **J.1 Airflow DAG migration** (依赖链调度；任务失败自动停止下游；可视化DAG视图) | DE强 | 高 | 3.5 days | ✅ Done 2026-07-17 — Airflow host scheduler replaced task.py; dependency chains per DAG |
| ⭐⭐ | F.10 Strategy Studio → Backtest execution pipeline | AI+Quant full-loop | High | 3-4 days | [ ] Pending — UI exists, need backtest adapter + quant_api endpoint |
| ⭐⭐ | F.4 LangGraph multi-agent research assistant | AI Engineer must-have | High | 2 weeks | [ ] Pending |
| ⭐⭐ | F.17 Portfolio Manager Agent (signals+positions→rebalance recommendation) | AI+Quant | 高 | 3 days | ✅ Done (2026-07-27) — review layer over the rule engine; 3 validation gates; 25 unit tests |
| ⭐⭐ | F.16 Real-time news monitoring agent (30min轮询→即时告警) | 实用价值高 | 高 | 3 days | [ ] Pending |
| ⭐⭐ | F.14 Earnings surprise prediction (pre-earnings beat/miss概率因子) | Quant+AI | 高 | 3 days | [ ] Pending |
| ⭐⭐ | F.12 Signal explanation SLM (为高评分股票生成原因解释→UI展示) | AI+UX | 中 | 2 days | [ ] Pending |
| ⭐⭐ | I.3 Alpaca order via MCP (LLM自主决策下单，保留风控) | AI自动交易 | 极高 | 2 days | [ ] Pending (after G.1+I.1) |
| ⭐⭐ | I.4 External data MCP tools (Finnhub/EDGAR/yfinance as Agent工具) | AI Agent基础 | 高 | 2 days | [ ] Pending |
| ⭐⭐ | F.15 SEC EDGAR + earnings transcript RAG | AI+Research | 中 | 3 days | [ ] Pending (after F.2) |
| ⭐⭐ | F.8 Active learning Agent (disagreement samples) | MLE+AI | High | 4 days | [ ] Pending |
| ⭐⭐ | **F.9 Rule Optimization Agent (iterative eval→modify loop)** | AI Engineer strong | 🔴 Fixes FP/FN in rule layer | 5-7 days | 🟡 Developed, not tested |
| ⭐⭐ | E.2 CI/CD GitHub Actions | DE strong | Medium | 2 days | [ ] Pending |
| ⭐⭐ | C.7 Data quality checks | DE strong | High | 2 days | ✅ Done (data_quality_check.py) |
| ⭐⭐ | **L.1 隔夜新闻动量策略** (15:30 情绪扫描→收盘买→次日开盘卖，无需小时线) | Quant+AI | 高 | 4 days | [ ] Pending (after G.1+J.3) |
| ⭐⭐ | **L.3 5分钟线数据基础设施** (Alpaca API backfill + 每日16:35增量 + 日内特征) | Quant+DE | 高 | 2 days | [ ] Pending (after G.1 Alpaca key) |
| ⭐ | **L.2 日内快速信号** (5分钟线 + Finnhub WebSocket实时新闻 → 日内动量) | Quant+AI | 中 | 2 weeks | [ ] Pending (after L.1+L.3) |
| ⭐⭐ | B quant bonus: Long-short portfolio | Quant strong | Medium | 3 days | [ ] Pending |
| ⭐⭐ | B quant bonus: Beta neutralization | Quant strong | Medium | 2 days | [ ] Pending |
| ⭐⭐ | F.5 FinBERT fine-tuning | MLE strong | High | 1-2 weeks | [ ] Pending |
| ⭐ | F.6 rule_validator ReAct Agent | AI bonus | Medium | 3 days | [ ] Pending |
| ⭐ | F.7 Airflow adaptive scheduling Agent | DE+AI | Medium | 3 days | [ ] Pending |
| ⭐⭐⭐ | D.1 Macro Regime features (merged into H.2) | Quant essential | 🔴 Real utility | 4 days | ✅ Done |
| ⭐ | E.4 K8s configuration | DE bonus | Low | 3 days | [ ] Pending |
| ⭐ | E.5 Data lineage diagram | DE bonus | Low | 2 days | [ ] Pending |
| ⭐ | E.6 WebSocket real-time push | Backend bonus | High | 3 days | [ ] Pending |
| ⭐ | E.9 UI intraday price chart (TradingView + Alpaca API) | UI bonus | Medium | 3 days | [ ] Pending — no hourly DB needed; Alpaca API on-demand |
| ⭐ | D.2 Retail sentiment | Quant bonus | Medium | 3 days | ✅ Done (StockTwits, not Reddit) |
| ⭐ | F.1 Prompt evaluation framework | MLE bonus | Medium | 2 days | [ ] Pending |
| ⭐ | F.11 News pre-filter SLM (双LLM前加轻量二分类，降70%推理量) | ML效率 | 中 | 3 days | [ ] Pending |
| ⭐ | F.13 Morning briefing agent (07:00盘前持仓简报) | 实用 | 中 | 2 days | [ ] Pending |
| ⭐ | F.18 Backtest reflection agent (自动诊断弱年份+生成报告) | Research | 低 | 2 days | [ ] Pending |
| ⭐ | F.19 LLM factor hypothesis generator (LLM建议新因子) | Research | 低 | 1 day | [ ] Pending |
| ⭐ | I.5 MCP inter-service (quant_ai→quant_api改MCP协议) | 架构 | 低 | 3 days | [ ] Pending (after I.1) |
| ⭐ | M.1 Point-in-time S&P 500 universe (survivorship-free) | QR essential | 🔴 Signal validity | 1-2 weeks | [ ] Pending (only if targeting QR roles) |
| ⭐ | M.2 PIT data hygiene audit (dirty dates, lookahead lineage) | QR essential | 🔴 Signal validity | 3 days | [ ] Pending |
| ⭐ | M.3 IC significance (Newey-West t-stat, decay, regime tables) | QR essential | Medium | 3 days | [ ] Pending |
| ⭐ | M.4 Sentiment orthogonalization vs momentum/size/sector | QR essential | 🔴 Core question | 1 week | [ ] Pending |
| ⭐ | M.5 Overfitting defenses (holdout, trial registry, deflated Sharpe) | QR essential | Medium | 2 days | [ ] Pending |
| ⭐ | M.6 Research report writeup (paper-style, honest conclusions) | QR essential | Medium | 3 days | [ ] Pending |
| — | D.4 Analyst rating changes | Quant bonus | Medium | 3 days | ✅ Done |
| — | D.7 Institutional 13F holdings change | Quant bonus | High | 3 days | ⚠️ **Withdrawn (M.7)** — the "strongest single factor, 60d IC=+0.20" was look-ahead: one undated row per symbol broadcast across all trade dates. Factor removed; net Sharpe 0.78→0.69 |
| — | D.8 Pre-market / after-hours price signals | Quant bonus | High | 1 day | ✅ Done (strongest short-term factor, 5d IC=+0.23) |

---

# Stage 5. Engineering Extensions (post-research)

Goal: after the research stages above produce a validated signal on a
50+ symbol universe, harden the system into a production-quality full-stack
showcase. These items are intentionally scoped to exercise three skill
areas — **Java backend**, **data engineering**, and **AI/ML engineering** —
so the project becomes a multi-role interview artifact.

Do not start these until:
- universe is expanded to 50+ symbols
- year-stability analysis is complete
- at least one signal has persistent positive excess return

## 5.1 Java Backend Track

### 5.1.1 Event-driven signal distribution (Kafka)
- Spring Boot microservice publishes daily signals to a Kafka topic
- Subscribers: UI push, alerting, risk control, audit log
- Requirements: idempotent consumers, dead-letter queue, schema registry
- Deliverables:
  - `quant_signal_publisher` service
  - Kafka broker + schema registry in docker-compose
  - consumer reference implementations
- Resume framing:
  *"Designed event-driven signal distribution system using Kafka,
  supporting 40+ symbols with sub-second latency and idempotent consumers."*

### 5.1.2 Backtest orchestration API
- REST endpoint to submit backtest jobs → async worker → WebSocket push
  results
- Resilience4j circuit breakers, Bucket4j rate limiting, Redis result cache
- Keycloak JWT for auth, role-based access (researcher vs admin)
- Deliverables:
  - new endpoints under `quant_api`
  - async job queue (RabbitMQ, already present)
  - WebSocket progress stream
- Resume framing:
  *"Built async backtest orchestration service with circuit breakers,
  rate limiting, and real-time result streaming over WebSocket."*

### 5.1.3 Admin dashboard backend
- CRUD for: stock universe, job schedules, backtest experiments,
  model versions
- Audit log of every mutation
- Expand `quant_ui` with admin views
- Resume framing:
  *"Implemented admin control plane with auditable CRUD for universe,
  scheduling, and model version management."*

## 5.2 Data Engineering Track

### 5.2.1 Airflow orchestration (replace `scheduler/task.py`)
- Migrate the current monolithic scheduler to Airflow DAGs
- One DAG per domain: news ingest, price history, feature build,
  backtest, model refresh
- Backfill support, SLA monitoring, retry policies
- Deliverables:
  - `airflow/dags/` directory
  - docker-compose service for Airflow webserver + scheduler
- Resume framing:
  *"Migrated monolithic scheduler to Airflow DAGs orchestrating 15+
  daily ETL jobs with backfill, SLA, and retry policies."*

### 5.2.2 Streaming news pipeline (Kafka + Flink)
- Replace batch GDELT collector with streaming ingest
- Flink jobs: dedup → content extraction → SLM relevance → fan-out to
  MongoDB (raw) and Qdrant (embeddings)
- Exactly-once semantics where possible
- Deliverables:
  - Flink job modules
  - Kafka topic design doc
- Resume framing:
  *"Built streaming news ingestion pipeline with Kafka + Flink
  processing 1M+ articles with exactly-once semantics."*

### 5.2.3 MLflow experiment tracking
- Every backtest + model training run logged to MLflow
- Parameters, metrics, artifacts, model registry
- Deliverables:
  - MLflow server in docker-compose (Postgres backend)
  - wrapper in `research/` scripts to log runs
- Resume framing:
  *"Implemented experiment tracking with MLflow, managing 100+ backtest
  runs and model versions across Ridge / HistGB / ensemble baselines."*

### 5.2.4 dbt transformations
- Model the MySQL / MongoDB feature derivations as dbt models
- Lineage graphs, schema tests, documentation
- Deliverables:
  - `dbt_project/` with staging / intermediate / mart layers
- Resume framing:
  *"Introduced dbt for data transformations, providing lineage graphs,
  automated tests, and self-documenting feature logic."*

## 5.3 AI / ML Engineering Track

### 5.3.1 RAG news search system
- Qdrant already deployed for Dify — add a second collection for
  news article embeddings
- Service: `/search?q=NVIDIA earnings beat` → semantic recall + LLM summary
- Embedding model: `text-embedding-nomic-embed-text-v1.5` (already in
  LM Studio)
- Deliverables:
  - embedding batch job for news_articles_company_matched_v2
  - FastAPI / Spring search service
  - simple UI search page
- Resume framing:
  *"Built RAG system over 1M+ financial news articles using Qdrant
  and local LLM, supporting semantic search and summarization."*

### 5.3.2 Multi-agent research assistant (LangGraph)
- Expand the existing `langchain-agent` container into a multi-agent graph:
  - data agent: pulls relevant news / prices / earnings
  - analysis agent: extracts events, generates hypotheses
  - strategy agent: proposes factor / portfolio adjustments
  - risk agent: validates constraints
- Orchestrated with LangGraph (stateful, branching)
- Deliverables:
  - `quant_langchain/` extension with agent graph
  - demo UI or CLI
- Resume framing:
  *"Designed multi-agent financial research system using LangGraph with
  specialized agents for news analysis, signal generation, and risk
  assessment."*

### 5.3.3 SLM fine-tuning for company-match
- Use the v2 matched dataset as labeled training data
- Fine-tune Qwen3.5-4B on the company-relevance task (LoRA)
- Benchmark: base vs fine-tuned on held-out set
- Target: +5% accuracy or -30% latency at equal accuracy
- Deliverables:
  - `research/finetune_slm.py` training script
  - before/after benchmark report
- Resume framing:
  *"Fine-tuned Qwen3.5-4B with LoRA on 500K+ article classification
  dataset, improving accuracy from X% to Y% and reducing inference
  latency by Z%."*

### 5.3.4 LLM-based feature generation
- Use a larger LLM to generate enrichment features per article:
  - sentiment (-1..+1)
  - event type (earnings / product / M&A / regulation / macro)
  - entity list (companies / people)
- Store as additional fields in v2
- Feed into feature pipeline as new daily aggregates
- Deliverables:
  - batch enrichment job
  - 5-10 new daily features
- Resume framing:
  *"Added LLM-based feature extraction (sentiment, event type, entities)
  to enrich 1M+ articles, contributing to a +X% lift in model IC."*

## 5.4 Integration: End-to-End MLOps Showcase

Single flagship deliverable that ties the three tracks together:

```
Kafka (news) → Flink (clean + SLM) → Feature Store
  → Model Inference API (Spring Boot) → Kafka (signals)
  → UI + Alerts + Audit
  → Prometheus / Grafana / OpenTelemetry (monitoring)
```

This touches: event streaming, Java backend, ML inference, observability,
cloud-native deployment — interview-ready for backend, data engineer,
and AI / ML engineer roles simultaneously.

Deliverables:
- architecture diagram (`docs/architecture.md`)
- all pieces deployable via a single `docker-compose up`
- README walkthrough of the full signal lifecycle

## 5.5 Execution Order (Stage 5)

Recommended build order, each item ~1-2 weeks:

1. **5.3.1 RAG news search** — quickest AI win, reuses existing Qdrant
2. **5.2.1 Airflow migration** — immediate data-engineering credential
3. **5.2.3 MLflow tracking** — low effort, high resume value
4. **5.1.1 Kafka signal publisher** — core event-driven piece
5. **5.3.2 Multi-agent system** — deepest AI showcase
6. **5.2.2 Flink streaming** — headline data-engineering item
7. **5.3.3 SLM fine-tuning** — after enough v2 data accumulates
8. **5.4 End-to-end integration** — final polish

## 5.6 Resume Skill Coverage Matrix

| Skill                       | Covered by              |
|-----------------------------|-------------------------|
| Spring Boot microservices   | 5.1.1, 5.1.2, 5.1.3     |
| Kafka / event-driven        | 5.1.1, 5.2.2, 5.4       |
| Resilience patterns         | 5.1.2                   |
| WebSocket / real-time       | 5.1.2                   |
| Airflow / orchestration     | 5.2.1                   |
| Flink / stream processing   | 5.2.2                   |
| MLflow / experiment tracking| 5.2.3                   |
| dbt / data modeling         | 5.2.4                   |
| RAG / vector search         | 5.3.1                   |
| LangGraph / multi-agent     | 5.3.2                   |
| LLM fine-tuning (LoRA)      | 5.3.3                   |
| LLM inference at scale      | 5.3.4, existing pipeline|
| Observability / monitoring  | 5.4                     |
| Docker / K8s deployment     | 5.4                     |

---

## Stage 6 — GDELT GKG Full Index Import into MongoDB (Implemented; `$text` index dropped 2026-10-07 — see 6.7 and Stage 6B)

### 6.1 Background and Goal

Matching historical GDELT data for new stocks currently requires scanning ~350,000 CSV files in batches, taking about 13 hours.
Goal: import 7 key columns from the CSVs into MongoDB and build a `$text` full-text index, reducing new-stock keyword matching from **13 hours → seconds**.

### 6.2 GDELT CSV column structure (7 columns retained)

| Col # | Field Name | MongoDB Field | Purpose |
|------|-----------|-----------------|------------------------|
| 1    | DATE      | `date`          | Publication date (YYYYMMDDHHMMSS) |
| 4    | URL       | `url`           | Article URL |
| 7    | V1Themes  | `themes`        | Theme keywords (primary matching) |
| 11   | V1Persons | `persons`       | Person names |
| 13   | V1Orgs    | `orgs`          | Organizations / company names (secondary matching) |
| 15   | V1Tone    | `tone`          | GCAM sentiment score (auxiliary feature) |
| 23   | AllNames  | `all_names`     | All entity names |

In the original 27-column CSV, column 17 (GCAM) accounts for 72% of the size; retaining 7 columns reduces data from 7TB to approximately **160 GB** (Parquet estimate), and MongoDB BSON + WiredTiger compression brings it to roughly **300–600 GB** (including `$text` index).

### 6.3 Development tasks

#### 6.3.1 Import script (`tools/gdelt_import_to_mongo.py`)

- Multi-process parallel read of `.csv` files (~350,000) from Data24T + Data6T
- Extract 7 columns per row; construct MongoDB document
- Write to collection `quant_data.gkg_index` in batches (batch_size=5000)
- Supports resume from checkpoint: imported files tracked in `gkg_import_progress` collection
- Deduplication: URL as unique key (`url` unique index)

```python
# Example document structure
{
    "date": "20200314120000",
    "url": "https://example.com/article",
    "themes": "ECON_BANKRUPTCY;ENV_SOLAR;...",
    "persons": "Tim Cook;Elon Musk;...",
    "orgs": "Apple Inc;Tesla;...",
    "tone": "2.5,-1.2,3.7,...",
    "all_names": "Apple-COMPANY;Tesla-COMPANY;..."
}
```

#### 6.3.2 Index creation

```javascript
// Compound text index (primary matching)
db.gkg_index.createIndex(
    { themes: "text", persons: "text", orgs: "text", all_names: "text" },
    { name: "gkg_text_idx", weights: { orgs: 10, themes: 5, all_names: 3, persons: 1 } }
)

// Auxiliary query indexes
db.gkg_index.createIndex({ date: 1 })
db.gkg_index.createIndex({ url: 1 }, { unique: true })
```

#### 6.3.3 New matching pipeline

Replace the current CSV batch scan in `historical_collector.py` with:

1. **Step 1**: `db.gkg_index.find({ $text: { $search: "keyword" } })` → returns candidate URL list in seconds
2. **Step 2**: Query `news_articles` collection; reuse already-fetched body text
3. **Step 3**: Fetch missing URLs (many old URLs from 2016-2020 may be dead; handle 404 gracefully)
4. **Step 4**: Write to `news_articles_company_matched_v2`

#### 6.3.4 Validation

- Pick 10 stocks from the existing 60; re-match using the new pipeline
- Compare URL hit rate against the current CSV approach to verify consistency
- Check `$text` index recall rate (any missed matches?)

### 6.4 Storage estimate

| Item | Estimated size |
|-----------------------------|------------|
| Raw CSV (7TB) → 7 columns extracted | ~160 GB |
| MongoDB BSON (uncompressed) | ~200 GB |
| After WiredTiger compression (~3.5x) | ~60 GB |
| `$text` index | ~200–400 GB |
| **Total (including index)** | **~300–600 GB** |

Once import is validated, the original CSVs can be deleted, saving **6TB+** of disk space.

### 6.5 Notes

- MongoDB server needs at least **600 GB** of free space (including temporary space for index build)
- Building the `$text` index will take **several hours** (570M records); recommended to create it all at once after import is complete
- V1Tone (`tone` field) format is comma-separated multiple scores; use the first value (overall sentiment score)
- Many old URLs (2016–2020) are likely dead; the URL fetching stage must handle 404/timeout gracefully and log the dead-link rate
- Import script must support parallel reads from multiple disks (Data24T + Data6T) to avoid single-disk I/O bottleneck

### 6.6 Prerequisites

- [ ] MongoDB server confirmed to have 600 GB+ free space
- [ ] Data24T and Data6T are mounted and readable
- [ ] After import, run regression tests on 10 sample stocks; delete original CSVs only after passing

### 6.7 Outcome (reviewed 2026-10-07)

What was actually built differs from 6.2–6.3:

| | Planned | Built |
|---|---|---|
| Fields | 7 columns (themes, persons, orgs, tone, all_names, …) | `{ts, url, raw}` — `raw` is "date + title", ~80 chars |
| `$text` index | on themes / persons / orgs / all_names | `gkg_raw_text` on `raw` |
| `url` index | unique | non-unique (`gkg_url`) |
| Size | 300–600 GB | 681M docs; data 301 GB on disk + indexes 370 GB (`$text` alone 325–328 GB) |

Findings on 2026-10-07, during a 2.5-month GDELT backfill (~7,480 GKG files):

1. **No code ever queried the `$text` index.** The only reader of `gkg_index` is
   `historical_collector.py`, and it uses `url` / `ts` point lookups. (`quant_ai/tools/hybrid_search.py`
   uses `$text` on a different collection.) The new-stock matching pipeline of 6.3.3 was never wired up.
2. **It made ingestion slow.** Every GKG file (~600 docs) took 8–17 s to import: the 325 GB index could not
   fit in MongoDB's 4 GB WiredTiger cache, half the cache sat dirty and application threads stalled on
   eviction. Downloading the same file takes under a second.
3. **It was corrupt.** WiredTiger checksum error in `index-0-3570980046893492215.wt` (the `$text` index) at
   offset 291 GB → fatal assertion 50853, mongod aborting and restarting 4 times in an hour (the same
   assertion first appeared 2026-09-24). Disk checks were clean (SMART verified, the block re-reads
   identically, no kernel I/O errors in 14 days) → most likely a torn write from the 2026-07-21 Docker-VM
   disk-full crash, not failing hardware. Collection data was not affected.

Actions taken: Docker VM memory 16 → 32 GB, `--wiredTigerCacheSizeGB` 4 → 20 (backfill went from ~6 to
~10 files/min); then **dropped `gkg_raw_text`** (backfill went to ~137 files/min, ~20x the original rate,
no more crashes). Full-history keyword search moves to Stage 6B.

---

## Stage 6B — GKG Columnar Store: Parquet + DuckDB (In progress, started 2026-10-07)

### 6B.1 Goal

Keep MongoDB for what it is good at (point lookups for de-duplication) and move full-history search and
statistics over `gkg_index` to a columnar copy, so neither workload slows the other down:

| Store | Holds | Serves | Indexes |
|---|---|---|---|
| MongoDB `quant_data.gkg_index` | source of truth: `ts`, `url`, `raw` | ingestion de-duplication (`url` upsert, "is this 15-min file already imported?" by `ts`), re-reading a file's rows by `ts` | `_id`, `url`, `ts` only (~42 GB) |
| Parquet `/Volumes/Data4T/gkg_parquet/month=YYYY-MM/part-0.parquet` | derived copy: `ts`, `url`, `raw` (zstd) | keyword search across all history (new-stock matching), counts / time-series statistics | none (month partitions + Parquet min/max stats) |

DuckDB is an embedded library, not a service: nothing to add to docker-compose or to project start-up.
Only the host Python environment needs `duckdb` (installed in `quant_data/.venv311`, version 1.5.6).

### 6B.2 Why not keep the `$text` index / why not ClickHouse

- New-stock matching happens a few times a year and is a batch job; a 1–3 minute scan is acceptable,
  while an always-maintained 325 GB index taxes every daily write (see 6.7).
- Writing to Parquet is an append of a new file; there is no index maintenance at all.
- ClickHouse would cover both workloads in one system but adds a server to run and maintain; for a
  single-maintainer project, files + an embedded engine are simpler. Revisit if interactive (sub-second)
  full-history search becomes a product requirement.
- Columnar storage is poor at single-row lookups by `url`, which is exactly what ingestion needs — hence
  the hybrid rather than replacing MongoDB.

### 6B.3 Tool: `quant_data/tools/gkg_parquet.py`

- `export --all | --months YYYY-MM … | --since-last` — rebuilds whole month files from MongoDB via the
  `gkg_ts` index; idempotent (a month is rewritten, never appended twice). Progress in `_export_state.json`.
- `search TERM [TERM …] [--from YYYY-MM] [--to YYYY-MM] [--limit N | --count]` — case-insensitive match on
  `raw`, newest first.
- `stats` — rows per month and size on disk.

### 6B.4 Validation so far (2026-10-07, one month)

| Check | Result |
|---|---|
| Export 2024-05 | 4,385,181 rows in 32 s |
| Row count vs MongoDB | 4,385,181 = 4,385,181 |
| Size on disk | 896 MB (~204 bytes/row) |
| `search Nvidia --count` (one month) | 4,798 rows in 1.0 s |
| `search Palantir --limit 3` (one month) | 1.0 s |

Extrapolated to all 681M rows: ~1.5 h one-off export, ~140 GB on disk, full-history keyword search
estimated at 1–3 min.

**Full export, 2026-10-08:** 683,950,529 rows in 4,064 s (~168K rows/s), 130 months
(2016-01 → 2026-10), 142.7 GB on disk. Per-month row counts checked against MongoDB (`ts` index,
117 s): all 130 months equal.

| Query (full history unless noted) | Rows | Time |
|---|---|---|
| `search Palantir --count` | 30,968 | 87 s |
| `search Palantir --limit 3` (newest first) | 3 | 88 s — `ORDER BY ts DESC` still scans everything; scanning newest months first and stopping at the limit would fix it |
| `search Nvidia --from 2025-01 --to 2025-12 --count` | 54,727 | 5 s |
| `search "Snowflake Inc" Snowflake --count` | 28,855 | 148 s |

### 6B.5 Tasks

- [x] Drop the corrupt `gkg_raw_text` index; resume `backfill_1_collect_and_match`
- [x] Write `tools/gkg_parquet.py` (export / search / stats); install `duckdb` in `.venv311`
- [x] Validate one month (6B.4)
- [x] Add `duckdb` (and `pyarrow`, previously only a transitive dependency) to `quant_data/requirements.txt`
- [x] Finish the 2026-07-21 → 2026-10-07 backfill (all 7,567 15-min slots to 2026-10-08 13:00 present;
      90 older files are 404 on GDELT's server — 2022-11-10/11 outage plus single days — and cannot be
      recovered), then `export --all` into `/Volumes/Data4T/gkg_parquet/`; test directory deleted
- [x] Verify: per-month row counts Parquet vs MongoDB (130/130 equal); benchmark (6B.4)
- [x] Add a `gkg_export` task to `backfill_1_collect_and_match` after `gdelt_collect`
      (`tools/gkg_parquet.py export --since-last`); first used 2026-10-08, after which Parquet
      and MongoDB both held 430,647 rows for 2026-10
- [ ] Wire new-stock matching (the never-built 6.3.3 pipeline) to `gkg_parquet.search()` instead of `$text`
- [ ] If a container ever needs to query Parquet (e.g. a UI history search), mount
      `/Volumes/Data4T/gkg_parquet` read-only into that service in docker-compose

### 6B.6 Phase 2 (optional, decide after 6B.5 is stable)

Slim `gkg_index` to `{ts, url}` by unsetting `raw` (data 301 GB → a few tens of GB). Prerequisite:
`historical_collector._gkg_query_rows()` reads `raw` by `ts` from MongoDB to re-process an already-imported
file; switch it to read the month's Parquet first, otherwise dropping `raw` breaks that path.

### 6B.6a GDELT pipeline now runs daily (2026-10-08)

The 2.5-month gap happened because `backfill_1_collect_and_match` had `schedule=None` — manual only —
and nothing ran it after 2026-07-21. Now:

- `backfill_1_collect_and_match`: `schedule="0 2 * * *"` (02:00 UTC); `gdelt_collect >> [company_match >>
  trigger_enrich, gkg_export]`. `trigger_enrich` starts `backfill_2_enrich_and_features`.
- `backfill_2_enrich_and_features`: `… >> feature_rebuild >> index_news_qdrant` (quant_ai
  `tools/index_news.py`, checkpointed by `_id`, so a day embeds only that day's articles — R.12).
- Requires LM Studio serving `qwen3.5-4b-mlx`, `gemma-4-e4b-it-mlx`, `qwen3.5-9b-mlx` and the nomic
  embedder at that hour (JIT loading is on). On the M5 Max the old aliases `qwen3.5-4b`,
  `qwen3.5-4b:2` and `google/gemma-4-e4b:2` do not exist (HTTP 400); the DAGs pin the `-mlx` ids and
  blank the second-instance variables.

**Bug fixed with it — the partial last batch.** Files are cut into 100-file batches in time order, so the
last batch is usually partial. Files GDELT publishes after a run land in that already-`done` batch.
`seed_tasks()` only filled `batch_sig` when it was NULL and never compared it, so those files reached
`gkg_index` (startup predownload) but never went through rules / SLM / article fetch — no articles. A
run every few weeks hid it (and Sunday's `gdelt_batch_verify` sometimes reopened the batch by luck); a
daily schedule would have dropped most of each day's news. `seed_tasks()` now reopens any batch whose
signature changed. First run with the fix reopened exactly the two stale batches, 2939 (last batch in
July) and 3014 (today's).

Increment from the 2026-07-21 → 2026-10-08 catch-up: 4,574,898 `gkg_index` rows, 37,623 new
`news_articles`, 14,933 `news_articles_company_matched_v2` (NVDA 1,737, GOOGL 1,707, TSLA 1,215,
MSFT 1,101, AMZN 1,016 …).

**First daily runs: LM Studio 500s, then a system freeze.** Pass B of the first two enrichment runs lost
240/241 and 282/283 articles to HTTP 500. Each time pass B fanned out 8 workers while `qwen3.5-9b-mlx`
was being (re)loaded, and LM Studio answers every request that arrives mid-load with `Model does not
exist` → 500. The third attempt (15:02) also froze the Mac hard — cursor included, manual reboot — with
Docker (24 GB) plus three models pinned in memory (gemma, 4b and 9b, loaded outside JIT so never evicted)
plus the 9b reload: 55 GB of process footprint on a 64 GB machine, and MLX weights are wired, so they
cannot be paged out. Fixes:

- `llm_enrich_articles.py` warms each model up with one request (up to 3 min) before fanning out,
  retries 5xx / connection errors with 2/5/15 s backoff, and sends `ttl=600` so a JIT-loaded model
  unloads after 10 idle minutes. With LM Studio's "unload previous JIT model on load", only one large
  model is resident at a time. Next run: 282/282 in 99 s, 0 errors.
- No models are pinned with `lms load` any more; everything loads on demand.
- `index_news.py` crashed with `UnboundLocalError` when there was nothing new to index; fixed.
- 4,033 Qdrant points had been embedded before their labels existed (empty `sentiment`); their payloads
  were back-filled from Mongo.

### 6B.7 Operational notes

- Docker Desktop VM memory is 20 GB and mongod runs with `--wiredTigerCacheSizeGB 12`
  (12 GB cache + ~2 GB mongod overhead + ~6 GB for the other containers). 24 GB left too little for
  LM Studio — see the freeze above. It was 32 GB / 20 GB for the
  backfill while the 325 GB `$text` index still existed; with that index gone, 20 GB plus the LM Studio
  models pushed the 64 GB Mac into 27 GB compressed + 12.6 GB swap. After the change: 44 GB used,
  1.3 GB compressed, 3.2 GB swap. Re-apply both after a Docker reinstall.
- MongoDB data, the GKG cache and the Parquet files all live on the external SSD `Data4T`. Back up
  MongoDB to a different disk — single node, no replica, and it has already crashed on corrupt pages.
- After dropping an index WiredTiger removes the file lazily; the 328 GB is reclaimed after a later
  checkpoint, not immediately.

---

# Stage 7 — New Mac Validation + Scheduled Task Verification + Execution Records (Pending development)

## 7.1 Background

A 48GB RAM Mac has been purchased and data/code migration is complete. A comprehensive validation of all services and scheduled tasks on the new machine is needed, along with adding observability for execution results.

## 7.2 Service validation

### 7.2.1 Docker service verification
- [ ] Verify all containers start correctly: mongo6 / quant_api / quant_ui / quant_data /
      airflow-webserver / airflow-scheduler / kafka / mlflow, etc.
- [ ] Check inter-service network connectivity (project-net internal communication)
- [ ] Verify external volume mounts are correct (MongoDB, MySQL, Airflow logs, etc. data intact)
- [ ] Confirm `.env` connection addresses are valid on the new machine

### 7.2.2 Airflow scheduled tasks running end-to-end (not just validation, must actually run)
- [ ] Check scheduling times and dependencies for all DAGs in `airflow/dags/`
- [ ] Manually trigger each DAG; confirm full end-to-end execution succeeds (not just "defined")
- [ ] Confirm Docker socket mount path is correct (`/var/run/docker.sock`)
- [ ] Wait for at least one automatic schedule trigger; confirm timed execution works
- [ ] Check DAG execution logs; fix any failing tasks
- [ ] Goal: news collection / feature build / model training — all three main DAGs running stably

### 7.2.3 Kafka actually running (not just deployed, must have real data flow)
- [ ] Confirm kafka container is healthy and reachable at `kafka:9092`
- [ ] Create required topics (e.g. `quant.signals`, `quant.news`)
- [ ] Implement at least one producer: push to `quant.signals` topic after daily signal generation
- [ ] Implement at least one consumer: consume signals and write to `daily_signals` collection or trigger alert
- [ ] Verify message flow through kafka-ui (port 15070)
- [ ] Goal: signal generation → Kafka → consume and write to DB — full pipeline running

### 7.2.4 MLflow actual run recording
- [ ] Confirm mlflow container is healthy (port 15050)
- [ ] Enable `--mlflow-uri` in `train_baseline_models.py`; run one training and record
- [ ] Verify parameters, metrics, and model files are visible in MLflow UI
- [ ] Goal: every model training run is recorded; IC / Top5 excess return is traceable

### 7.2.5 LLM inference validation
- [ ] Verify LM Studio / Ollama is available on the new Mac and models are loaded
- [ ] Verify `SLM_API_URL` environment variable points to the correct endpoint
- [ ] Run a small batch of `llm_enrich_articles.py` to confirm inference is working

## 7.3 Execution result recording (UI / API)

Current problem: execution results for Airflow and Python scripts (success/failure, rows processed, duration, key metrics) have no unified visibility entry point, making troubleshooting difficult.

### 7.3.1 quant_api execution log endpoint
- [ ] Add `pipeline_runs` collection (MongoDB) or table (MySQL) to record each task execution:
  ```json
  {
    "task_name": "feature_build",
    "started_at": "2026-05-22T21:00:00Z",
    "finished_at": "2026-05-22T21:03:00Z",
    "status": "success",
    "rows_processed": 134642,
    "error_message": null,
    "metadata": { "collection": "daily_symbol_features_company_matched_v2" }
  }
  ```
- [ ] quant_api provides REST endpoints: `POST /api/pipeline-runs` (write) and
      `GET /api/pipeline-runs` (query most recent N records)
- [ ] Each Python script (daily_symbol_features.py, llm_enrich_articles.py, etc.)
      calls the endpoint to report results after completion

### 7.3.2 quant_ui execution history page
- [ ] Add a "Task Execution Records" page in the UI showing:
  - Task name, status (success/failure), start/end time, rows processed
  - Execution trend chart for the last 30 days
  - Failed tasks highlighted + error message display
- [ ] Support filtering by task name and time range

### 7.3.3 Model training result persistence
- [ ] After each `train_baseline_models.py` run, write per-horizon IC / Top5 excess return
      to `model_results` collection with timestamp and feature set version tag
- [ ] quant_ui displays model historical result trends to facilitate comparison across different feature versions

## 7.4 Priority

1. Docker baseline service validation (blocks all subsequent work)
2. **Airflow DAG actually running** (not just defined; must run stably — key interview proof)
3. **Kafka producer/consumer actually running** (signal → topic → consume and write to DB full pipeline)
4. **MLflow actual run recording** (every training run is traceable)
5. quant_api execution log endpoint (pipeline_runs write to DB)
6. quant_ui execution history page
7. Model result persistence

---

## G. Reference Resources (compiled 2026-05-22)

### G.1 LLM sentiment factor / alpha mining papers

| Paper | Key points |
|------|------|
| [Event-Aware Sentiment Factors from LLM-Augmented Financial Tweets (arXiv 2508.07408)](https://arxiv.org/pdf/2508.07408) | Interpretable LLM quantitative framework, event-aware sentiment factor construction; useful to compare against this project's LLM tagging approach |
| [Interpretable ML for Macro Alpha: News Sentiment Case Study (arXiv 2505.16136)](https://arxiv.org/pdf/2505.16136) | FinBERT + GDELT → FX/treasury strategy, OOS Sharpe >4; validates the GDELT + LLM approach |
| [AlphaAgent: LLM-Driven Alpha Mining (arXiv 2502.16789)](https://arxiv.org/html/2502.16789v2) | LLM-automated alpha factor mining including anti-decay mechanism |
| [Automate Strategy Finding with LLM in Quant Investment (arXiv 2409.06289)](https://arxiv.org/html/2409.06289v1) | LLM-driven strategy discovery pipeline; useful prompt design reference |

### G.2 CBOE options data (free download)

- **PCR historical CSV** (for D.5 Put/Call Ratio factor):
  `https://cdn.cboe.com/resources/options/volume_and_call_put_ratios/indexpcarchive.csv`
- **CBOE historical data main page**:
  `https://www.cboe.com/us/options/market_statistics/historical_data/`
- Usage: load daily PCR data directly with `pd.read_csv(url)`; no registration required

### G.3 FinBERT fine-tuning resources (for F.5 / Stage 3.5.5)

| Resource | Key points |
|------|------|
| [Fine-Tuning FinBERT for Sector-Specific Financial News (MDPI Electronics 2025)](https://www.mdpi.com/2079-9292/14/23/4680) | zero-shot F1=0.555 → after fine-tuning F1=**0.707**; includes sector-specific training approach, directly applicable as training script reference |
| [ProsusAI/finbert on HuggingFace](https://huggingface.co/ProsusAI/finbert) | Official FinBERT pre-trained weights, ready to load |
| [Efficient FinBERT via Quantization (ACL FinNLP 2025)](https://aclanthology.org/2025.finnlp-2.6.pdf) | INT8/INT4 quantization compression; runnable locally on Mac M-series chips |

### G.4 SEC EDGAR 13F Python tools (for D.7)

| Library | Description |
|----|------|
| [edgartools](https://github.com/dgunning/edgartools) | **Preferred**, free and open-source; parses 13F into structured Python objects; data goes back to 2005; `pip install edgartools` |
| [sec-api-python](https://github.com/janlukasschroeder/sec-api-python) | Paid SDK with free trial quota; suitable for bulk production scraping |

---

## H. Live Trading System Roadmap (from research → truly usable)

### Background: why live trading is not yet possible

Backtest results (long-short annualized +21.7%, Sharpe 0.85) look promising, but the following issues would cause real money to lose:

| Problem | Specific manifestation | Risk level |
|------|---------|---------|
| IC year-over-year instability | IC was negative in 2022/2024/2025, signal reversed | 🔴 Fatal |
| No transaction costs | Backtest does not deduct commissions + slippage; real returns reduced by 30-40% | 🔴 Fatal |
| Signal lag | LLM processing takes several hours after news is published | 🟡 Serious |
| No position sizing | Equal-weight allocation; single-stock risk is unconstrained | 🟡 Serious |
| No out-of-sample validation | All data used for backtest; overfitting risk | 🟡 Serious |
| Only 100 stocks | Concentration too high; liquidity risk | 🟠 Moderate |

---

### H.1 Fix backtest realism (🔴 must do first)

**H.1.1 Add transaction cost model**
- One-way commission: 0.05% (standard broker level)
- Slippage model: 0.3% for small-cap, 0.1% for large-cap (tiered by market cap)
- Modify `backtest_news_factor.py` and `backtest_event_driven.py`:
  ```python
  net_return = gross_return - commission * 2 - slippage * 2
  ```
- Goal: determine how much of the long-short annualized return remains after costs
- Status: [x] Done — `backtest_portfolio.py`: COMMISSION_BPS=5, liquidity-tiered slippage 10/30bps, $5M min dollar-volume filter; measured 30.4 bps round trip

**H.1.2 Add liquidity filter**
- Exclude stocks with average daily volume < $5M (avoid execution failure)
- Add `avg_daily_volume` feature; filter at position selection
- Status: [ ] Pending development (0.5 days)

**H.1.3 Add position limit constraints**
- Max position per stock: 5% (avoid over-concentration)
- Max position per sector: 25%
- Modify `score_daily_signals.py` to add position constraint logic
- Status: [ ] Pending development (0.5 days)

---

### H.2 Resolve IC instability (🔴 must do first)

**H.2.1 Market Regime detection**

Year-by-year IC analysis reveals the signal is only effective in "trending markets":
```
2022 (bear market / high VIX): IC = -0.035 → disable signal
2023 (recovery / low VIX):     IC = +0.163 → enable signal  
2024 (choppy):                  IC = -0.022 → disable signal
2025 (choppy):                  IC = -0.020 → disable signal
```

Implementation:
- Data source: `yfinance` for daily VIX data
- Regime definitions:
  - **Trending market**: VIX < 20 AND SPY 20-day moving average trending up → enable LLM sentiment factor weighting
  - **Choppy / panic**: VIX > 25 → reduce position to 50%, switch to mean-reversion factors
- New field: `market_regime` (trend / volatile / crisis)
- Adjust composite_score weights by regime in `score_daily_signals.py`
- Status: [x] Done (2026-07-15) — `_WEIGHTS_BY_REGIME` in `score_daily_signals.py`, four regimes (RISK_ON / NEUTRAL / STRESSED / RISK_OFF) switched on VIX percentile and SPY vs 200MA

**H.2.2 Dynamic factor weights**
- Different factor weights for different regimes:
  - Trending market: LLM sentiment weight 40%, momentum weight 30%, earnings weight 30%
  - Choppy market: LLM sentiment weight 10%, mean-reversion weight 50%, earnings weight 40%
- Add `market_regime` as a feature during model training, or train separate models per regime
- Status: [ ] Pending development (2 days)

---

### H.3 Paper Trading validation (🔴 must do, run for at least 3-6 months)

**Goal**: validate signals in a real market environment and accumulate out-of-sample data

**H.3.1 Paper Trading engine**
- Execute automatically after market close each day:
  1. Read the top 10 stocks by composite_score from that day's `daily_signals`
  2. Check regime: if VIX > 25, skip or halve the position
  3. Simulate order entry; record entry price (use next day's open price)
  4. Write to `paper_positions` collection
- Fields: `symbol`, `entry_date`, `entry_price`, `size`, `score_at_entry`, `regime_at_entry`
- Status: [x] Done (2026-07-15) — `track_positions.py`: vol-adaptive stop-loss at 2x vol_20d plus a rolling OOS IC monitor

**H.3.2 Paper Trading performance tracking**
- Update unrealized P&L daily
- Compute real out-of-sample IC (each day's actual holdings: predicted vs actual performance)
- Target metrics:
  - OOS IC > 0.02 (signal is effective in real markets)
  - OOS Sharpe > 0.5 (strategy is executable)
  - 3 consecutive months of positive excess return (signal is stable)
- Status: [ ] Pending development (1 day)

**H.3.3 Stop-loss and exit logic**
- Per-stock stop-loss: auto-exit if the position drops -5% from entry
- Sentiment reversal stop-loss: if `avg_sentiment_5d` turns negative during holding, actively exit
- Time stop-loss: auto-exit if holding exceeds `max_hold_days` (default 45 days)
- Status: [ ] Pending development (1 day)

---

### H.4 Signal quality monitoring (🟡 important)

**H.4.1 Real-time IC monitoring**
- Compute rolling IC over the most recent 20 trading days every day
- If IC stays below 0 for 5 consecutive days → trigger alert, pause new position entries
- Write to `signal_quality` collection; UI displays IC trend chart
- Status: [ ] Pending development (1 day)

**H.4.2 Model drift detection**
- Weekly: compare the latest feature distribution against the training-time distribution (KL divergence)
- If distribution shift exceeds threshold → trigger retraining reminder
- Status: [ ] Pending development (1 day)

---

### H.5 Live trading readiness checklist

All of the following must be satisfied before considering real capital:

- [ ] Paper trading has run for **at least 3 months**, OOS IC > 0.02
- [ ] Backtest Sharpe **remains > 0.5** after including transaction costs
- [ ] Regime detection works correctly; automatically reduces position when VIX > 25
- [ ] Stop-loss logic tested (simulated extreme market conditions)
- [ ] Max position per stock ≤ 5%; overall leverage = 1x (no leverage)
- [ ] Broker API connected (Interactive Brokers / Alpaca)
- [ ] First live-trading capital ≤ 10% of total capital (testing phase)

---

### H. Roadmap overview

```
Now (research validation complete)
    ↓
H.1 Fix backtest realism (3 days)        ← know the real returns
H.2 Regime detection (4 days)            ← know when to use the signal
H.3 Paper Trading (1 month to get going) ← real-market validation
    ↓ continue running 3-6 months
H.4 Signal monitoring (2 days)           ← keep signal effective
    ↓ paper trading metrics pass
H.5 Live trading checklist all ✓
    ↓
Small live position (≤10% of total capital)
    ↓ 6 months of stable excess return
Truly usable quantitative trading system ✓
```

---

## G. Strategy Generation Complete Implementation Plan (quant_langchain)

> Current state: `quant_langchain/main.py` already has the endpoint framework for `/api/workflow/generate-spec` and `/api/workflow/generate-tasks`, but all three core features are stub implementations that need to be completed.

---

### G.1 RAG — Replace keyword matching with vector retrieval (3 days)

**Current problems:**
- `retrieve_context()` scores by keyword token overlap, not semantic retrieval
- The knowledge directory has only 1 file (26 lines); RAG has almost no real effect
- Low hit rate: user input "RSI mean reversion" cannot match if phrased differently

**Goal:** Replace keyword matching with Qdrant (already running in docker-compose) for true vector semantic retrieval

**Development steps:**

1. **Add knowledge base documents** (1 day)
   - `knowledge/strategies/` — strategy templates: RSI, MACD, momentum, mean-reversion examples
   - `knowledge/factors/` — factor descriptions: IC per factor, use cases, parameter ranges
   - `knowledge/risk/` — risk control rules: stop-loss, position, max drawdown defaults
   - `knowledge/modules/` — detailed parameter descriptions for each module in MODULE_CATALOG

2. **Integrate Qdrant vector retrieval** (2 days)
   - Install: `langchain-qdrant`, `sentence-transformers`
   - Embed knowledge documents with `all-MiniLM-L6-v2`; write to Qdrant
   - Replace `retrieve_context()` with `qdrant_client.search(query_vector, top_k=4)`
   - Build index asynchronously at startup; support incremental updates

**Done when:** Input "RSI buy when oversold" retrieves the RSI strategy template document

---

### G.2 MCP — Tools actually executable (4 days)

**Current problems:**
- Module paths in `MODULE_CATALOG` (e.g. `quant_langchain.features.momentum`) do not exist
- LLM only "sees" the tool list in the prompt; it cannot actually call them
- No tool call loop: module names in the LLM-generated spec are hallucinated and never executed

**Goal:** Wrap each tool in MODULE_CATALOG as a callable function; close the loop of LLM → tool call → result returned

**Development steps:**

1. **Implement tool functions** (2 days)

```python
# quant_langchain/tools/market_data.py
def fetch_market_data(symbols: list, timeframe: str, lookback_days: int) -> dict:
    """Call quant_api /api/signals to fetch historical signals and price data"""
    resp = requests.get(f"{QUANT_API}/api/signals", params={"symbols": symbols})
    return resp.json()

# quant_langchain/tools/feature_builder.py
def build_features(indicators: list, window: int) -> dict:
    """Call quant_api /api/features to get feature data"""
    ...

# quant_langchain/tools/backtest.py
def backtest_strategy(spec: dict, initial_cash: int, fee_bps: int) -> dict:
    """Generate backtest summary based on spec (calls quant_data research module)"""
    ...
```

2. **Register tools with LangChain** (1 day)
   - Register each function with the `@tool` decorator
   - Change the `generate-spec` endpoint to use `AgentExecutor` so the LLM actually calls tools
   - Collect results from each tool call and assemble into the final spec

3. **MCP protocol wrapping (optional upgrade)** (1 day)
   - Add JSON schema description for each tool
   - Output format complies with MCP tool result spec
   - Prepares for future Claude MCP integration

**Done when:** Spec generation logs show `[Tool Call] fetch_market_data(AAPL, daily, 60)` → real data returned

---

### G.3 API Key routing — proactive tiering by task complexity (1 day)

**Current problems:**
- Uses `OpenAI` (text completion); should switch to `ChatOpenAI` (chat model)
- Routing logic only falls back when Ollama is down; no proactive model selection by task type
- `LLMChain` is a deprecated API; should migrate to LCEL (LangChain Expression Language)

**Goal:** Local small model handles simple tasks; cloud large model handles complex reasoning

**Routing rules:**

| Task | Model | Reason |
|------|------|------|
| generate-spec (simple strategy) | Qwen3-8B local | MODULE_CATALOG constrains output; structure is fixed |
| generate-spec (complex multi-factor) | Claude Sonnet / GPT-4o | Factor combination reasoning; small models hallucinate |
| generate-tasks (code generation) | Claude Sonnet / GPT-4o | High code quality required |
| chat (strategy Q&A) | Qwen3-8B local | Many conversation turns; cost-sensitive |

**Development steps:**

```python
# Switch to ChatOpenAI + LCEL
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate

def get_llm(task_type: str = "simple"):
    # Proactively use cloud model for complex tasks
    if task_type == "code_generation" and ANTHROPIC_API_KEY:
        return ChatAnthropic(model="claude-sonnet-4-6", api_key=ANTHROPIC_API_KEY)
    if task_type == "complex_spec" and OPENAI_API_KEY:
        return ChatOpenAI(model="gpt-4o-mini", api_key=OPENAI_API_KEY)
    # Default to local
    try:
        # health check Ollama...
        return ChatOllama(model=LOCAL_MODEL_NAME)
    except:
        return ChatOpenAI(model="gpt-4o-mini", api_key=OPENAI_API_KEY)
```

**Done when:** generate-tasks endpoint logs show `[Router] task=code_generation → claude-sonnet-4-6`

---

### G.4 Priority and time estimate

| Priority | Feature | Effort | Value |
|--------|------|--------|------|
| 🔴 Highest | G.2 MCP tools actually executable | 4 days | Strategy generation changes from "hallucinated output" to "real execution" |
| 🟠 High | G.3 API Key routing refactor | 1 day | Code quality improvement; deprecated API removed |
| 🟡 Medium | G.1 RAG vector retrieval | 3 days | Retrieval precision improved; interview demo highlight |

**Total timeline: approximately 8 days**

Recommended order: G.3 (1 day, base layer) → G.2 (4 days, tool layer) → G.1 (3 days, knowledge layer)

**Estimated time from now to "truly usable": approximately 6-9 months** (of which 3-6 months is waiting for paper trading data to accumulate)
