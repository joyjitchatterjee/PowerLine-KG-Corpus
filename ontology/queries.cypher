// ============================================================================
// PowerLine Inspection Ontology - Decision Support Queries
// Example Cypher queries for operational use
// ============================================================================


// ---------------------------------------------------------------------------
// Q1: FULL CAUSAL CHAIN TRAVERSAL
//     "Given a defect detected on a component, what is the end-to-end risk?"
//
//     This is the core decision-support query. A VLM detects corrosion on a
//     yoke suspension -> what failure mode does it cause -> what is the risk?
//
//     NOTE: the maintenance action is conditioned on the assessed severity via
//     the `when_severity` property of REQUIRES, so the action is joined to its
//     severity level (one action per level). Matching (d)-[:REQUIRES]->(ma)
//     without that join returns the whole rule table as a cartesian product.
// ---------------------------------------------------------------------------

MATCH (d:DefectType {name: 'corrosion'})-[:AFFECTS]->(c:ComponentType {name: 'yoke_suspension'}),
      (d)-[lt:LEADS_TO]->(fm:FailureMode)-[:IMPACTS]->(r:Risk),
      (d)-[:HAS_SEVERITY]->(s:Severity),
      (d)-[req:REQUIRES]->(ma:MaintenanceAction)
WHERE req.when_severity = s.level
  AND (lt.component_context IS NULL OR lt.component_context = c.name)
RETURN c.name AS component,
       d.name AS defect,
       s.level AS severity_level,
       s.label AS severity_label,
       fm.name AS failure_mode,
       fm.description AS failure_description,
       r.name AS risk,
       r.risk_score AS risk_score,
       r.consequence AS consequence,
       ma.name AS recommended_action,
       ma.urgency AS urgency,
       ma.typical_timeframe AS timeframe
ORDER BY s.level;


// ---------------------------------------------------------------------------
// Q2: DECISION SUPPORT FROM VLM OBSERVATION
//     "The VLM says it sees 'missing cap on glass insulator' - what do we do?"
//
//     Simulates the VLM -> KG bridge: match observation text to defect + component
// ---------------------------------------------------------------------------

// First, create a sample Observation node (as the VLM pipeline would)
CREATE (obs:Observation {
  observation_id: 'OBS-DEMO-001',
  text: 'Glass insulator string with one cap missing from the third disc position. Remaining discs appear intact. Light contamination visible on lower discs.',
  confidence: 0.87,
  model: 'BLIP-2'
});

// Then query the causal chain from the mentioned defect.
// The severity-conditioned action is resolved by joining REQUIRES.when_severity
// to the severity level, so each row carries exactly one action for its level.
MATCH (d:DefectType {name: 'missing_cap'})-[:AFFECTS]->(c:ComponentType {name: 'glass_insulator'}),
      (d)-[:HAS_SEVERITY]->(s:Severity),
      (d)-[:LEADS_TO]->(fm:FailureMode)-[:IMPACTS]->(r:Risk),
      (d)-[req:REQUIRES]->(ma:MaintenanceAction)
WHERE req.when_severity = s.level
RETURN c.name AS component,
       d.name AS defect,
       s.level AS severity_level,
       s.label AS severity_label,
       fm.name AS failure_mode,
       r.name AS risk,
       r.risk_score AS risk_score,
       ma.name AS action,
       ma.urgency AS urgency,
       ma.typical_timeframe AS timeframe
ORDER BY s.level DESC;


// ---------------------------------------------------------------------------
// Q3: COMPONENT RISK PROFILE
//     "Show me all possible defects, failure modes, and risks for a given component"
// ---------------------------------------------------------------------------

MATCH (d:DefectType)-[:AFFECTS]->(c:ComponentType {name: 'vari-grip'}),
      (d)-[:LEADS_TO]->(fm:FailureMode)-[:IMPACTS]->(r:Risk)
RETURN c.name AS component,
       d.name AS defect,
       d.category AS defect_category,
       fm.name AS failure_mode,
       fm.impact_type AS impact_type,
       r.name AS risk,
       r.risk_score AS risk_score
ORDER BY r.risk_score DESC;


// ---------------------------------------------------------------------------
// Q4: ENVIRONMENTAL RISK AMPLIFICATION
//     "Given a coastal environment, which defects are amplified and on what components?"
// ---------------------------------------------------------------------------

MATCH (env:Environment {environment_id: 'ENV-COASTAL'})-[ir:INCREASES_RISK]->(d:DefectType)-[:AFFECTS]->(c:ComponentType)
RETURN env.name AS environment,
       d.name AS defect,
       ir.factor AS risk_multiplier,
       ir.mechanism AS mechanism,
       collect(c.name) AS affected_components
ORDER BY ir.factor DESC;


// ---------------------------------------------------------------------------
// Q5: STANDARD COMPLIANCE CHECK
//     "Which standards apply to this component, and what failure modes do they mitigate?"
// ---------------------------------------------------------------------------

MATCH (c:ComponentType {name: 'polymer_insulator'})-[:CONFORMS_TO]->(std:Standard),
      (std)-[:MITIGATES]->(fm:FailureMode)
RETURN c.name AS component,
       std.name AS standard,
       std.description AS standard_scope,
       fm.name AS mitigated_failure_mode,
       fm.impact_type AS impact_type;


// ---------------------------------------------------------------------------
// Q6: MAINTENANCE PRIORITY RANKING
//     "Rank all defect-component combinations by risk score for maintenance planning"
// ---------------------------------------------------------------------------

MATCH (d:DefectType)-[:AFFECTS]->(c:ComponentType),
      (d)-[:LEADS_TO]->(fm:FailureMode)-[:IMPACTS]->(r:Risk),
      (d)-[req:REQUIRES]->(ma:MaintenanceAction)
WITH c.name AS component, d.name AS defect,
     max(r.risk_score) AS max_risk,
     collect(DISTINCT {when_severity: req.when_severity,
                       action: ma.name,
                       urgency: ma.urgency}) AS actions_by_severity
RETURN component, defect, max_risk, actions_by_severity
ORDER BY max_risk DESC;


// ---------------------------------------------------------------------------
// Q7: ASSEMBLY CONTEXT
//     "What other components are structurally related to a defective part?"
//     Useful for: if shackle is corroded, what else might be affected?
// ---------------------------------------------------------------------------

MATCH (c:ComponentType {name: 'polymer_insulator_upper_shackle'})-[:ATTACHES_TO]->(parent:ComponentType)
OPTIONAL MATCH (sibling:ComponentType)-[:ATTACHES_TO]->(parent)
WHERE sibling.name <> c.name
RETURN c.name AS defective_component,
       parent.name AS parent_assembly,
       collect(sibling.name) AS related_components_to_inspect;


// ---------------------------------------------------------------------------
// Q8: HIGHEST-RISK COMPONENTS IN THE ASSET
//     "Which components on this transmission line carry the highest aggregate risk?"
// ---------------------------------------------------------------------------

MATCH (c:ComponentType)-[:PART_OF]->(a:Asset),
      (d:DefectType)-[:AFFECTS]->(c),
      (d)-[:LEADS_TO]->(fm:FailureMode)-[:IMPACTS]->(r:Risk)
WITH c.name AS component, c.supercategory AS category,
     avg(r.risk_score) AS avg_risk,
     count(DISTINCT d) AS num_possible_defects,
     collect(DISTINCT fm.name) AS failure_modes
RETURN component, category, avg_risk, num_possible_defects, failure_modes
ORDER BY avg_risk DESC;


// ---------------------------------------------------------------------------
// Q9: INGESTING A NEW IMAGE WITH DETECTIONS
//     Template for the data pipeline to add inspection results into the graph
// ---------------------------------------------------------------------------

// Example: UAV captures image, detection model finds a polymer insulator,
// VLM observes housing damage, severity assessed as moderate

CREATE (img:Image {
  image_id: 'IMG-TOWER284-PHASE-A-001',
  file_name: '284-1_DJI_0495.jpg',
  timestamp: datetime('2020-11-15T10:30:00'),
  source: 'DJI_Matrice_210_V2',
  quality_score: 0.92
})
WITH img

// Link to detected component
MATCH (ct:ComponentType {name: 'polymer_insulator'})
CREATE (img)-[:HAS_COMPONENT {
  bbox: [633, 415, 837, 342],
  detection_confidence: 0.97,
  detector_model: 'DetectoRS'
}]->(ct)
WITH img

// Link to detected defect
MATCH (dt:DefectType {name: 'housing_tear'})
CREATE (img)-[:HAS_DEFECT {
  classification_confidence: 0.84,
  classifier_model: 'EfficientNet-B2',
  assessed_severity: 2
}]->(dt)
WITH img

// Add VLM observation
CREATE (obs:Observation {
  observation_id: 'OBS-284-A-001',
  text: 'Polymer insulator with visible tear in the silicone rubber housing near the second shed from the bottom end fitting. The tear is approximately 5cm long and appears to expose the underlying fibreglass rod. No active tracking marks visible yet.',
  confidence: 0.87,
  model: 'BLIP-2'
})
CREATE (img)-[:HAS_OBSERVATION]->(obs)
WITH obs

// Link observation to entities it mentions
MATCH (ct:ComponentType {name: 'polymer_insulator'})
CREATE (obs)-[:MENTIONS]->(ct)
WITH obs
MATCH (dt:DefectType {name: 'housing_tear'})
CREATE (obs)-[:MENTIONS]->(dt);


// ---------------------------------------------------------------------------
// Q10: END-TO-END DECISION QUERY FROM IMAGE
//      "For this specific image, what is the full assessment and recommendation?"
// ---------------------------------------------------------------------------

// The image's assessed severity (stored on the HAS_DEFECT edge) selects the
// single severity-conditioned action via REQUIRES.when_severity.
MATCH (img:Image {image_id: 'IMG-TOWER284-PHASE-A-001'})
      -[:HAS_COMPONENT]->(c:ComponentType),
      (img)-[hd:HAS_DEFECT]->(d:DefectType),
      (img)-[:HAS_OBSERVATION]->(obs:Observation),
      (d)-[:LEADS_TO]->(fm:FailureMode)-[:IMPACTS]->(r:Risk),
      (d)-[req:REQUIRES]->(ma:MaintenanceAction)
WHERE req.when_severity = hd.assessed_severity
OPTIONAL MATCH (c)-[:CONFORMS_TO]->(std:Standard)-[:MITIGATES]->(fm)
RETURN img.image_id AS image,
       img.file_name AS file,
       c.name AS component,
       d.name AS defect,
       hd.assessed_severity AS assessed_severity,
       obs.text AS vlm_observation,
       fm.name AS failure_mode,
       fm.description AS failure_description,
       r.name AS risk,
       r.risk_score AS risk_score,
       r.consequence AS consequence,
       ma.name AS recommended_action,
       ma.urgency AS urgency,
       ma.typical_timeframe AS timeframe,
       collect(DISTINCT std.name) AS applicable_standards;
