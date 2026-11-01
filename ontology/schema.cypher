// ============================================================================
// PowerLine Inspection Ontology - Schema Definition
// Neo4j constraints, indexes, and structural setup
//
// Causal chain: Image -> Component -> Defect -> Severity -> FailureMode -> Risk
// Lateral influence: Environment, SensorReading, Standard
// Operational: MaintenanceAction
// Perception: Observation (VLM output)
// ============================================================================

// ---------------------------------------------------------------------------
// 1. UNIQUENESS CONSTRAINTS
// ---------------------------------------------------------------------------

// Perception layer
CREATE CONSTRAINT image_id IF NOT EXISTS
  FOR (i:Image) REQUIRE i.image_id IS UNIQUE;

CREATE CONSTRAINT image_file_path IF NOT EXISTS
  FOR (i:Image) REQUIRE i.file_path IS UNIQUE;

CREATE CONSTRAINT observation_id IF NOT EXISTS
  FOR (o:Observation) REQUIRE o.observation_id IS UNIQUE;

CREATE CONSTRAINT image_annotation_id IF NOT EXISTS
  FOR (a:ImageAnnotation) REQUIRE a.annotation_id IS UNIQUE;

CREATE CONSTRAINT evidence_case_id IF NOT EXISTS
  FOR (e:EvidenceCase) REQUIRE e.case_id IS UNIQUE;

CREATE CONSTRAINT dataset_id IF NOT EXISTS
  FOR (d:Dataset) REQUIRE d.dataset_id IS UNIQUE;

// Physical layer
CREATE CONSTRAINT asset_id IF NOT EXISTS
  FOR (a:Asset) REQUIRE a.asset_id IS UNIQUE;

CREATE CONSTRAINT component_type_name IF NOT EXISTS
  FOR (c:ComponentType) REQUIRE c.name IS UNIQUE;

CREATE CONSTRAINT condition_label IF NOT EXISTS
  FOR (c:Condition) REQUIRE c.label IS UNIQUE;

// Defect layer
CREATE CONSTRAINT defect_type_name IF NOT EXISTS
  FOR (d:DefectType) REQUIRE d.name IS UNIQUE;

CREATE CONSTRAINT severity_level IF NOT EXISTS
  FOR (s:Severity) REQUIRE s.level IS UNIQUE;

// Causal layer
CREATE CONSTRAINT failure_mode_name IF NOT EXISTS
  FOR (f:FailureMode) REQUIRE f.name IS UNIQUE;

// Context layer
CREATE CONSTRAINT environment_id IF NOT EXISTS
  FOR (e:Environment) REQUIRE e.environment_id IS UNIQUE;

// Knowledge layer
CREATE CONSTRAINT standard_name IF NOT EXISTS
  FOR (st:Standard) REQUIRE st.name IS UNIQUE;

// Operational layer
CREATE CONSTRAINT maintenance_action_name IF NOT EXISTS
  FOR (m:MaintenanceAction) REQUIRE m.name IS UNIQUE;

CREATE CONSTRAINT work_order_template_id IF NOT EXISTS
  FOR (w:WorkOrderTemplate) REQUIRE w.template_id IS UNIQUE;

// Decision layer
CREATE CONSTRAINT risk_id IF NOT EXISTS
  FOR (r:Risk) REQUIRE r.risk_id IS UNIQUE;

// Simulation and agent layer
CREATE CONSTRAINT simulation_run_id IF NOT EXISTS
  FOR (s:SimulationRun) REQUIRE s.run_id IS UNIQUE;

CREATE CONSTRAINT simulation_model_id IF NOT EXISTS
  FOR (s:SimulationModel) REQUIRE s.model_id IS UNIQUE;

CREATE CONSTRAINT agent_role_name IF NOT EXISTS
  FOR (a:AgentRole) REQUIRE a.name IS UNIQUE;

CREATE CONSTRAINT embedding_run_id IF NOT EXISTS
  FOR (e:EmbeddingRun) REQUIRE e.run_id IS UNIQUE;

// ---------------------------------------------------------------------------
// 2. INDEXES FOR QUERY PERFORMANCE
// ---------------------------------------------------------------------------

// Component lookups by material and category
CREATE INDEX component_material IF NOT EXISTS
  FOR (c:ComponentType) ON (c.material);

CREATE INDEX component_category IF NOT EXISTS
  FOR (c:ComponentType) ON (c.supercategory);

// Defect lookups by category
CREATE INDEX defect_category IF NOT EXISTS
  FOR (d:DefectType) ON (d.category);

// Image lookups by source file
CREATE INDEX image_filename IF NOT EXISTS
  FOR (i:Image) ON (i.file_name);

CREATE INDEX image_component_canonical IF NOT EXISTS
  FOR (i:Image) ON (i.component_canonical);

CREATE INDEX image_condition_label IF NOT EXISTS
  FOR (i:Image) ON (i.condition_label);

CREATE INDEX image_source_dataset IF NOT EXISTS
  FOR (i:Image) ON (i.source_dataset);

CREATE INDEX image_split IF NOT EXISTS
  FOR (i:Image) ON (i.split);

CREATE INDEX image_task IF NOT EXISTS
  FOR (i:Image) ON (i.task);

// Risk score for decision-support queries
CREATE INDEX risk_score IF NOT EXISTS
  FOR (r:Risk) ON (r.risk_score);

// Failure mode impact type for filtering
CREATE INDEX failure_impact IF NOT EXISTS
  FOR (f:FailureMode) ON (f.impact_type);

// Maintenance action urgency
CREATE INDEX maintenance_urgency IF NOT EXISTS
  FOR (m:MaintenanceAction) ON (m.urgency);

// Simulation feature filters for benchmark queries
CREATE INDEX simulation_condition IF NOT EXISTS
  FOR (s:SimulationRun) ON (s.condition);

CREATE INDEX simulation_risk_score IF NOT EXISTS
  FOR (s:SimulationRun) ON (s.risk_score);

// Full-text index on observation text for VLM output search
CREATE FULLTEXT INDEX observation_text IF NOT EXISTS
  FOR (o:Observation) ON EACH [o.text];

CREATE FULLTEXT INDEX work_order_template_text IF NOT EXISTS
  FOR (w:WorkOrderTemplate) ON EACH [w.title, w.description];

// Human annotations retain their own provenance, separate from predictions.
CREATE CONSTRAINT human_annotation_id IF NOT EXISTS
  FOR (a:HumanAnnotation) REQUIRE a.record_id IS UNIQUE;
