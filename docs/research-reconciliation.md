# Research reconciliation for final submission

Status: open, 7 October 2026. The project owner confirms the study results are real and original records exist. No participant-level recalculation has been performed in this change, and no replacement observations have been invented.

## Source reviewed

The supplied seven-page PDF, **A Mobile-Controlled Educational Robotics Prototype for Children Aged 7–12: System Design and a Preliminary Evaluation Report**, describes commit `2d9cf79` and already distinguishes repository-reported aggregates from independent reanalysis. Pages 4–6 state that participant-level scores, assessment/coding records, the study software version and ethics identifiers are not included. Its printed tables were inspected as well as its extracted text.

The supplied folder contains the paper and a revised LaTeX source; no participant-score spreadsheet/CSV, session-level dataset or original statistical analysis was located. The paper repeats selected aggregates, so it cannot resolve contradictions in the source records by itself. The current firmware/app repairs are a new development revision and must not be retroactively described as the software used in the earlier pilot.

## Open checks

1. **CTA overall versus age cohorts.** The stated group sizes and rounded means imply weighted means 42.6167 / 80.0083; the overall table reports 42.3 / 79.8. Confirm cohort membership, missing-data handling and source calculations before replacing either set.
2. **Engagement summaries.** A median of 42 minutes is inconsistent with 67% of the same observations exceeding 45 minutes. The phase means weighted by 3/5/4 sessions give 44.1667 minutes, versus the reported overall 45.3. Identify whether statistics use sessions, child-level averages, distinct observation windows or different samples.
3. **Headline outcome.** CTA changes from 42.3 to 79.8, an 88.65% relative change. The PCMS subscale means sum to 58.1 and 146.1, a 151.46% relative change. The previous "89% programming concept improvement" conflated outcomes. The README now avoids the ambiguous headline.
4. **Delayed follow-up.** The [archived curriculum](archive/curriculum-guide.md)'s six-/twelve-month claims conflict with the research document's statement that no extended follow-up occurred. Keep them explicitly pending verification until the dates, participants, measurements and analysis are supplied.
5. **Inference and study design.** Reproduce tests/effect sizes from the actual data, document the repeated-measures standardizer, and avoid interpreting an uncontrolled pre/post change as a comparative or causal effect. The paper's descriptive d_RMS calculation from rounded summaries does not independently verify paired observations or a p-value.
6. **Traceability.** Identify the firmware/app version used during the pilot, assessment instruments/rubrics, anonymized participant IDs, consent/ethics approval identifier and date, and provenance of quotations/coding. Keep identifying participant and consent records private; an appropriately controlled access process is sufficient.
7. **Literature.** Add complete bibliographic entries and check each numerical attribution. Benitti (2012) includes ten selected articles; 197 refers to the initial search/screening pool, not the final included study count. Unverified cost/access/effect-size percentages should not be reused as established findings.

## Records needed to close this item

- Anonymized participant-by-time-point CTA and PCMS scores, subgroup membership and missing-data flags.
- Session logs with duration definitions, session/child identifiers and completion outcomes/denominators.
- Any genuine delayed follow-up records and dates.
- Analysis scripts or spreadsheet formulas and assessment/scoring materials.
- Study-version identification and private confirmation of ethics/consent documentation.

After those records are available, regenerate all publication tables from a single analysis, reconcile both Markdown documents and paper, and review the corrected output. Until then, retain the original reported data with this qualification and do not mark the research P1 closed.

The active curriculum and user manual were rewritten on 8 October 2026 to match the repaired five-level app. Their earlier versions, including original reported figures and proposed features, are preserved under `docs/archive/`. The rewrite is not a revision of the study dataset or proof of the software used in the pilot.
