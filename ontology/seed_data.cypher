// ============================================================================
// PowerLine Inspection Ontology - Seed Data
// Domain knowledge for decision support on the InsPLAD dataset
//
// Causal chain: Image -> Component -> Defect -> Severity -> FailureMode -> Risk
// Grounded in a 500 kV transmission line inspection (northeast Brazil)
// ============================================================================

// ---------------------------------------------------------------------------
// 1. ASSET (the transmission line itself)
// ---------------------------------------------------------------------------

CREATE (a:Asset {
  asset_id: 'STN-500kV-NE-001',
  name: 'STN 500 kV Transmission Line',
  type: 'overhead_transmission_line',
  voltage_level: 500,
  voltage_unit: 'kV',
  region: 'Northeast Brazil',
  operator: 'STN - Sistema de Transmissao Nordeste',
  num_towers_inspected: 226,
  phases: ['A', 'B', 'C'],
  health_index: NULL
});

// ---------------------------------------------------------------------------
// 1A. HUMAN DESCRIPTION CORPUS
// ---------------------------------------------------------------------------

CREATE (ds_human:Dataset {
  dataset_id: 'INSPLAD-HUMAN-DESCRIPTIONS-85',
  name: 'Human-annotated InsPLAD descriptions',
  record_count: 85,
  source_path: 'data/annotations.jsonl',
  annotation_source: 'human_labelled_workbook'
});

// ---------------------------------------------------------------------------
// 2. COMPONENT TYPES (all 18 classes from InsPLAD-det COCO annotations)
//    supercategory: 'componente' = primary functional component
//                   'suporte'    = support/attachment hardware
// ---------------------------------------------------------------------------

// --- Primary Components (componente) ---

CREATE (ct_yoke:ComponentType {
  name: 'yoke',
  supercategory: 'componente',
  material: 'galvanized_steel',
  function: 'Distributes mechanical load from insulator strings to the tower crossarm. Connects multiple conductor sub-spans at a suspension point.',
  position: 'tower_crossarm',
  typical_failure_modes: ['corrosion', 'fatigue_cracking', 'bolt_loosening']
})

CREATE (ct_spacer:ComponentType {
  name: 'spacer',
  supercategory: 'componente',
  material: 'aluminium_alloy',
  function: 'Maintains fixed separation between sub-conductors in a bundled conductor configuration. Prevents galloping and sub-span oscillation.',
  position: 'mid_span',
  typical_failure_modes: ['arm_fracture', 'clamp_slip', 'corrosion']
})

CREATE (ct_stockbridge:ComponentType {
  name: 'stockbridge_damper',
  supercategory: 'componente',
  material: 'galvanized_steel_zinc',
  function: 'Attenuates aeolian vibration on the conductor by dissipating energy through counter-weight oscillation. Protects conductor from fatigue failure at clamp points.',
  position: 'near_tower_clamp',
  typical_failure_modes: ['counterweight_detachment', 'messenger_wire_fatigue', 'clamp_corrosion']
})

CREATE (ct_polymer_ins:ComponentType {
  name: 'polymer_insulator',
  supercategory: 'componente',
  material: 'fibreglass_core_silicone_housing',
  function: 'Provides electrical insulation between the energised conductor and the grounded tower structure. The silicone rubber housing sheds water to maintain leakage distance under contaminated/wet conditions.',
  position: 'between_tower_and_conductor',
  typical_failure_modes: ['tracking_erosion', 'housing_tear', 'brittle_fracture', 'flashover']
})

CREATE (ct_glass_ins:ComponentType {
  name: 'glass_insulator',
  supercategory: 'componente',
  material: 'toughened_glass',
  function: 'Provides electrical insulation via a string of glass discs. Self-shattering property allows easy visual identification of failed units from the ground or UAV.',
  position: 'between_tower_and_conductor',
  typical_failure_modes: ['missing_cap', 'disc_shatter', 'pin_corrosion', 'flashover']
})

CREATE (ct_plate:ComponentType {
  name: 'tower_id_plate',
  supercategory: 'componente',
  material: 'painted_metal',
  function: 'Identifies the transmission tower with a unique alphanumeric code. Critical for asset management, emergency response, and maintenance dispatch.',
  position: 'tower_body',
  typical_failure_modes: ['peeling_paint', 'illegibility', 'physical_damage']
})

CREATE (ct_spiral:ComponentType {
  name: 'spiral_damper',
  supercategory: 'componente',
  material: 'PVC_helical',
  function: 'Reduces aeolian vibration on overhead ground wires (OPGW/shield wire) by altering aerodynamic profile and adding distributed mass.',
  position: 'near_tower_clamp_shield_wire',
  typical_failure_modes: ['unwinding', 'UV_degradation', 'detachment']
})

CREATE (ct_sphere:ComponentType {
  name: 'sphere',
  supercategory: 'componente',
  material: 'fibreglass_or_aluminium',
  function: 'Aviation warning sphere (marker ball) installed on overhead ground wire to increase visibility for low-flying aircraft near airports or heliports.',
  position: 'mid_span_ground_wire',
  typical_failure_modes: ['fading', 'cracking', 'detachment']
})

// --- Support / Attachment Hardware (suporte) ---

CREATE (ct_yoke_susp:ComponentType {
  name: 'yoke_suspension',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Suspends the yoke plate from the tower crossarm. Transfers the vertical mechanical load of the conductor bundle to the tower structure.',
  position: 'tower_crossarm_attachment',
  typical_failure_modes: ['corrosion', 'pin_wear', 'fatigue_cracking']
})

CREATE (ct_lr_shackle:ComponentType {
  name: 'lightning_rod_shackle',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Connects the lightning rod (shield wire) suspension assembly to the tower peak. Must withstand impulse loads from lightning strikes.',
  position: 'tower_peak',
  typical_failure_modes: ['corrosion', 'bolt_loosening', 'wear']
})

CREATE (ct_lr_susp:ComponentType {
  name: 'lightning_rod_suspension',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Suspends the overhead ground wire (lightning rod / shield wire) from the tower peak. Provides mechanical support and allows limited swing under wind loading.',
  position: 'tower_peak',
  typical_failure_modes: ['corrosion', 'fatigue_cracking', 'hinge_seizure']
})

CREATE (ct_varigrip:ComponentType {
  name: 'vari-grip',
  supercategory: 'suporte',
  material: 'aluminium_alloy_steel',
  function: 'Dead-end compression clamp that terminates the conductor at a strain tower. Transfers full conductor tension to the tower through the insulator string.',
  position: 'strain_tower_conductor_termination',
  typical_failure_modes: ['corrosion', 'bird_nest_accumulation', 'compression_failure']
})

CREATE (ct_poly_lower:ComponentType {
  name: 'polymer_insulator_lower_shackle',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Bottom-end fitting connecting the polymer insulator string to the conductor-side hardware (yoke or clamp). Subject to full conductor tension.',
  position: 'insulator_conductor_end',
  typical_failure_modes: ['corrosion', 'pin_wear', 'cotter_pin_loss']
})

CREATE (ct_poly_upper:ComponentType {
  name: 'polymer_insulator_upper_shackle',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Top-end fitting connecting the polymer insulator string to the tower-side hardware. Transfers the mechanical load to the tower crossarm.',
  position: 'insulator_tower_end',
  typical_failure_modes: ['corrosion', 'bolt_loosening', 'wear']
})

CREATE (ct_poly_tower:ComponentType {
  name: 'polymer_insulator_tower_shackle',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Tower-side attachment bracket for the polymer insulator string. Anchors directly to the crossarm structure.',
  position: 'tower_crossarm_bracket',
  typical_failure_modes: ['corrosion', 'bracket_deformation', 'bolt_loosening']
})

CREATE (ct_glass_big:ComponentType {
  name: 'glass_insulator_big_shackle',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Large shackle fitting at the tower end of the glass insulator string. Interfaces with the tower crossarm hardware.',
  position: 'insulator_tower_end',
  typical_failure_modes: ['corrosion', 'wear', 'pin_deformation']
})

CREATE (ct_glass_small:ComponentType {
  name: 'glass_insulator_small_shackle',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Small shackle fitting at the conductor end of the glass insulator string. Connects to the yoke or conductor clamp.',
  position: 'insulator_conductor_end',
  typical_failure_modes: ['corrosion', 'wear', 'pin_deformation']
})

CREATE (ct_glass_tower:ComponentType {
  name: 'glass_insulator_tower_shackle',
  supercategory: 'suporte',
  material: 'galvanized_steel',
  function: 'Tower-side attachment bracket for the glass insulator string. Directly bolted to the crossarm steel.',
  position: 'tower_crossarm_bracket',
  typical_failure_modes: ['corrosion', 'bracket_deformation', 'bolt_loosening']
});

// ---------------------------------------------------------------------------
// 3. STRUCTURAL RELATIONSHIPS: Component PART_OF Asset
// ---------------------------------------------------------------------------

MATCH (a:Asset {asset_id: 'STN-500kV-NE-001'})
MATCH (c:ComponentType)
CREATE (c)-[:PART_OF]->(a);

// ---------------------------------------------------------------------------
// 4. COMPONENT ASSEMBLY RELATIONSHIPS
//    Which support hardware attaches to which primary component
// ---------------------------------------------------------------------------

// Yoke assembly
MATCH (ys:ComponentType {name: 'yoke_suspension'})
MATCH (y:ComponentType {name: 'yoke'})
CREATE (ys)-[:ATTACHES_TO {role: 'suspends yoke from crossarm'}]->(y);

// Polymer insulator assembly
MATCH (pu:ComponentType {name: 'polymer_insulator_upper_shackle'})
MATCH (pi:ComponentType {name: 'polymer_insulator'})
CREATE (pu)-[:ATTACHES_TO {role: 'tower-end fitting'}]->(pi);

MATCH (pl:ComponentType {name: 'polymer_insulator_lower_shackle'})
MATCH (pi:ComponentType {name: 'polymer_insulator'})
CREATE (pl)-[:ATTACHES_TO {role: 'conductor-end fitting'}]->(pi);

MATCH (pt:ComponentType {name: 'polymer_insulator_tower_shackle'})
MATCH (pi:ComponentType {name: 'polymer_insulator'})
CREATE (pt)-[:ATTACHES_TO {role: 'tower crossarm bracket'}]->(pi);

// Glass insulator assembly
MATCH (gb:ComponentType {name: 'glass_insulator_big_shackle'})
MATCH (gi:ComponentType {name: 'glass_insulator'})
CREATE (gb)-[:ATTACHES_TO {role: 'tower-end fitting'}]->(gi);

MATCH (gs:ComponentType {name: 'glass_insulator_small_shackle'})
MATCH (gi:ComponentType {name: 'glass_insulator'})
CREATE (gs)-[:ATTACHES_TO {role: 'conductor-end fitting'}]->(gi);

MATCH (gt:ComponentType {name: 'glass_insulator_tower_shackle'})
MATCH (gi:ComponentType {name: 'glass_insulator'})
CREATE (gt)-[:ATTACHES_TO {role: 'tower crossarm bracket'}]->(gi);

// Lightning rod assembly
MATCH (ls:ComponentType {name: 'lightning_rod_shackle'})
MATCH (lr:ComponentType {name: 'lightning_rod_suspension'})
CREATE (ls)-[:ATTACHES_TO {role: 'tower peak attachment'}]->(lr);

// Conductor termination
MATCH (vg:ComponentType {name: 'vari-grip'})
MATCH (y:ComponentType {name: 'yoke'})
CREATE (vg)-[:CONNECTS_TO {role: 'dead-end conductor termination at strain tower'}]->(y);

// Damper placement on conductor
MATCH (sd:ComponentType {name: 'stockbridge_damper'})
MATCH (y:ComponentType {name: 'yoke'})
CREATE (sd)-[:PROTECTS {role: 'aeolian vibration damping near suspension point'}]->(y);

MATCH (sp:ComponentType {name: 'spiral_damper'})
MATCH (lr:ComponentType {name: 'lightning_rod_suspension'})
CREATE (sp)-[:PROTECTS {role: 'vibration damping on shield wire'}]->(lr);

// ---------------------------------------------------------------------------
// 4A. CONDITION VOCABULARY
// ---------------------------------------------------------------------------

CREATE (cond_normal:Condition {
  label: 'normal',
  description: 'No visible defect or simulation degradation is indicated. Used for good image examples and healthy simulation runs.'
})

CREATE (cond_defective:Condition {
  label: 'defective',
  description: 'A visible defect, simulated degraded state, or abnormal condition is present and should be considered by the reasoner.'
});

// ---------------------------------------------------------------------------
// 5. DEFECT TYPES (grounded in InsPLAD observed defects)
// ---------------------------------------------------------------------------

CREATE (d_rust:DefectType {
  name: 'corrosion',
  category: 'surface',
  description: 'Oxidation and material degradation of metallic surfaces. Manifests as orange-brown discoloration, pitting, and eventual material loss. Accelerated by coastal/humid environments.',
  detectability: 'visual',
  aliases: ['rust', 'oxidation', 'corrosao']
})

CREATE (d_misscap:DefectType {
  name: 'missing_cap',
  category: 'structural',
  description: 'One or more glass insulator discs have shattered or detached from the string. Reduces the total insulation leakage distance and withstand voltage.',
  detectability: 'visual',
  aliases: ['missingcap', 'broken_disc', 'shattered_disc']
})

CREATE (d_nest:DefectType {
  name: 'bird_nest',
  category: 'environmental',
  description: 'Accumulation of bird nesting material (twigs, grass, debris) on or around hardware. Reduces electrical clearance and may bridge insulation gaps.',
  detectability: 'visual',
  aliases: ['nest', 'bird-nest', 'bird_nest_presence']
})

CREATE (d_torn:DefectType {
  name: 'housing_tear',
  category: 'structural',
  description: 'Physical damage or tearing of the polymer insulator silicone rubber housing. Exposes the fibreglass core rod to moisture ingress, leading to brittle fracture risk.',
  detectability: 'visual',
  aliases: ['torned-up', 'torn_housing', 'housing_damage']
})

CREATE (d_paint:DefectType {
  name: 'peeling_paint',
  category: 'surface',
  description: 'Degradation and flaking of paint on the tower identification plate. Leads to loss of legibility of the tower number, complicating maintenance dispatch and emergency response.',
  detectability: 'visual',
  aliases: ['peeling-paint', 'paint_degradation', 'fading']
});

// ---------------------------------------------------------------------------
// 6. DEFECT -> COMPONENT MAPPINGS (AFFECTS relationships)
//    Grounded in actual InsPLAD dataset observations
// ---------------------------------------------------------------------------

// Corrosion affects many metallic components
MATCH (d:DefectType {name: 'corrosion'})
MATCH (c:ComponentType)
WHERE c.name IN [
  'yoke_suspension', 'lightning_rod_suspension', 'polymer_insulator_upper_shackle',
  'vari-grip', 'stockbridge_damper', 'glass_insulator_big_shackle',
  'glass_insulator_tower_shackle', 'lightning_rod_shackle',
  'polymer_insulator_lower_shackle', 'polymer_insulator_tower_shackle',
  'yoke', 'glass_insulator_small_shackle'
]
CREATE (d)-[:AFFECTS]->(c);

// Missing cap affects glass insulator
MATCH (d:DefectType {name: 'missing_cap'})
MATCH (c:ComponentType {name: 'glass_insulator'})
CREATE (d)-[:AFFECTS]->(c);

// Bird nest affects vari-grip and small shackle areas
MATCH (d:DefectType {name: 'bird_nest'})
MATCH (c:ComponentType)
WHERE c.name IN ['vari-grip', 'glass_insulator_small_shackle']
CREATE (d)-[:AFFECTS]->(c);

// Housing tear affects polymer insulator
MATCH (d:DefectType {name: 'housing_tear'})
MATCH (c:ComponentType {name: 'polymer_insulator'})
CREATE (d)-[:AFFECTS]->(c);

// Peeling paint affects tower ID plate
MATCH (d:DefectType {name: 'peeling_paint'})
MATCH (c:ComponentType {name: 'tower_id_plate'})
CREATE (d)-[:AFFECTS]->(c);

// ---------------------------------------------------------------------------
// 7. SEVERITY LEVELS (from annotator guidelines)
// ---------------------------------------------------------------------------

CREATE (s0:Severity {
  level: 0,
  label: 'normal',
  description: 'No defect indicated. Used for negative-control images and healthy simulation runs.',
  risk_weight: 0.0
})

CREATE (s1:Severity {
  level: 1,
  label: 'minor',
  description: 'Cosmetic or early-stage degradation. No immediate impact on mechanical or electrical function. Example: light surface oxidation, minor paint fading.',
  risk_weight: 0.2
})

CREATE (s2:Severity {
  level: 2,
  label: 'moderate',
  description: 'Noticeable degradation that warrants scheduled maintenance. Structural integrity or insulation margin is measurably reduced. Example: significant corrosion around bolt holes, single missing insulator cap.',
  risk_weight: 0.5
})

CREATE (s3:Severity {
  level: 3,
  label: 'severe',
  description: 'Condition poses safety risk or imminent failure. Immediate or priority intervention required. Example: extensive corrosion with material loss, multiple missing discs, large bird nest bridging clearance.',
  risk_weight: 1.0
});

// Ordinal structure of the four-level severity scale: each level escalates to
// the next. This makes the ordering explicitly traversable in the graph
// (mirrors the reasoner's Bound stage, which may escalate one level).
MATCH (sa:Severity), (sb:Severity)
WHERE sb.level = sa.level + 1
CREATE (sa)-[:ESCALATES_TO]->(sb);

// ---------------------------------------------------------------------------
// 8. DEFECT -> SEVERITY MAPPINGS (typical severity per defect type)
//    Level 0 ('normal') is reserved for defect-free evidence (images and
//    healthy simulation runs); a DefectType is never linked to level 0.
// ---------------------------------------------------------------------------

// Corrosion ranges from minor (surface) to severe (structural loss)
MATCH (d:DefectType {name: 'corrosion'}), (s:Severity)
WHERE s.level >= 1
CREATE (d)-[:HAS_SEVERITY {condition: CASE s.level
  WHEN 1 THEN 'Light surface oxidation, <10% area, no pitting'
  WHEN 2 THEN 'Moderate corrosion 10-40% area, visible pitting around bolt holes'
  WHEN 3 THEN 'Extensive corrosion >40% area, material loss, section reduction'
  END}]->(s);

// Missing cap
MATCH (d:DefectType {name: 'missing_cap'}), (s:Severity)
WHERE s.level >= 2
CREATE (d)-[:HAS_SEVERITY {condition: CASE s.level
  WHEN 2 THEN 'Single cap missing, adequate remaining leakage distance'
  WHEN 3 THEN 'Multiple caps missing, flashover risk under contamination or rain'
  END}]->(s);

// Bird nest
MATCH (d:DefectType {name: 'bird_nest'}), (s:Severity)
WHERE s.level >= 2
CREATE (d)-[:HAS_SEVERITY {condition: CASE s.level
  WHEN 2 THEN 'Small nest, not bridging live-to-ground clearance'
  WHEN 3 THEN 'Large nest bridging clearance or contacting energised parts, fire/flashover risk'
  END}]->(s);

// Housing tear
MATCH (d:DefectType {name: 'housing_tear'}), (s:Severity)
WHERE s.level >= 2
CREATE (d)-[:HAS_SEVERITY {condition: CASE s.level
  WHEN 2 THEN 'Minor tear in outer silicone shed, core rod not exposed'
  WHEN 3 THEN 'Deep tear exposing fibreglass core rod, moisture ingress and brittle fracture risk'
  END}]->(s);

// Peeling paint (generally minor to moderate)
MATCH (d:DefectType {name: 'peeling_paint'}), (s:Severity)
WHERE s.level >= 1 AND s.level <= 2
CREATE (d)-[:HAS_SEVERITY {condition: CASE s.level
  WHEN 1 THEN 'Partial fading, tower number still legible'
  WHEN 2 THEN 'Significant paint loss, tower number barely legible or illegible'
  END}]->(s);

// ---------------------------------------------------------------------------
// 9. FAILURE MODES (what can happen if defect is left unaddressed)
// ---------------------------------------------------------------------------

CREATE (fm_mech:FailureMode {
  name: 'mechanical_failure',
  impact_type: 'safety',
  description: 'Loss of mechanical strength leading to hardware fracture or conductor drop. May result in line-to-ground fault, conductor on ground, or tower collapse cascade.'
})

CREATE (fm_flash:FailureMode {
  name: 'insulation_flashover',
  impact_type: 'outage',
  description: 'Dielectric breakdown across the insulator string causing a phase-to-ground arc. Triggers protection relay trip and forced outage. Repeated flashover damages hardware.'
})

CREATE (fm_fire:FailureMode {
  name: 'fire_hazard',
  impact_type: 'safety',
  description: 'Combustible material (bird nest, vegetation) ignited by leakage current or arc. Risk of bushfire ignition in vegetated corridors.'
})

CREATE (fm_tracking:FailureMode {
  name: 'tracking_erosion',
  impact_type: 'efficiency',
  description: 'Progressive carbonised tracking paths on polymer insulator surface under pollution+moisture. Degrades insulation performance over time, eventually leading to flashover.'
})

CREATE (fm_brittle:FailureMode {
  name: 'brittle_fracture',
  impact_type: 'safety',
  description: 'Catastrophic failure of polymer insulator fibreglass core rod due to moisture ingress through damaged housing. Occurs without warning under normal mechanical load - the insulator separates and the conductor drops.'
})

CREATE (fm_id_loss:FailureMode {
  name: 'asset_identification_loss',
  impact_type: 'efficiency',
  description: 'Tower identification number becomes illegible. Delays emergency response, complicates maintenance scheduling, and creates asset register discrepancies.'
})

CREATE (fm_clearance:FailureMode {
  name: 'clearance_violation',
  impact_type: 'safety',
  description: 'Reduction of electrical clearance between live conductor and grounded structure due to foreign object (nest, vegetation). Increases probability of flashover under transient overvoltage.'
});

CREATE (fm_aeolian:FailureMode {
  name: 'aeolian_vibration_fatigue',
  impact_type: 'reliability',
  description: 'Progressive conductor strand fatigue at clamps or suspension points due to wind-induced aeolian vibration when damping is insufficient or detuned.'
});

// ---------------------------------------------------------------------------
// 10. DEFECT -> FAILURE MODE CAUSAL LINKS (LEADS_TO)
// ---------------------------------------------------------------------------

// Corrosion leads to mechanical failure
MATCH (d:DefectType {name: 'corrosion'}), (f:FailureMode {name: 'mechanical_failure'})
CREATE (d)-[:LEADS_TO {mechanism: 'Section loss reduces load-bearing capacity below design safety factor. Galvanic corrosion at bimetallic joints accelerates under coastal salt spray.'}]->(f);

// Missing cap leads to flashover
MATCH (d:DefectType {name: 'missing_cap'}), (f:FailureMode {name: 'insulation_flashover'})
CREATE (d)-[:LEADS_TO {mechanism: 'Each missing disc reduces the string withstand voltage. Under contamination + rain, the effective leakage distance may fall below the minimum required for the system voltage.'}]->(f);

// Bird nest leads to fire hazard and clearance violation
MATCH (d:DefectType {name: 'bird_nest'}), (f:FailureMode {name: 'fire_hazard'})
CREATE (d)-[:LEADS_TO {mechanism: 'Dry nesting material in proximity to energised conductor. Leakage current through damp nest or direct arc ignition.'}]->(f);

MATCH (d:DefectType {name: 'bird_nest'}), (f:FailureMode {name: 'clearance_violation'})
CREATE (d)-[:LEADS_TO {mechanism: 'Nest material extends from grounded hardware toward live conductor, reducing the air gap below design clearance.'}]->(f);

// Housing tear leads to tracking/erosion and brittle fracture
MATCH (d:DefectType {name: 'housing_tear'}), (f:FailureMode {name: 'tracking_erosion'})
CREATE (d)-[:LEADS_TO {mechanism: 'Damaged silicone housing traps moisture and contaminants, creating localised high E-field regions where tracking initiates.'}]->(f);

MATCH (d:DefectType {name: 'housing_tear'}), (f:FailureMode {name: 'brittle_fracture'})
CREATE (d)-[:LEADS_TO {mechanism: 'Torn housing allows moisture to reach the fibreglass core rod. Acid attack (from nitric acid generated by corona discharge + moisture) causes stress corrosion cracking of the GRP rod.'}]->(f);

// Peeling paint leads to identification loss
MATCH (d:DefectType {name: 'peeling_paint'}), (f:FailureMode {name: 'asset_identification_loss'})
CREATE (d)-[:LEADS_TO {mechanism: 'Progressive paint degradation from UV exposure and weathering renders the tower number illegible.'}]->(f);

// Stockbridge damper corrosion reduces damping and can increase wind-induced fatigue
MATCH (d:DefectType {name: 'corrosion'}), (f:FailureMode {name: 'aeolian_vibration_fatigue'})
CREATE (d)-[:LEADS_TO {
  component_context: 'stockbridge_damper',
  mechanism: 'Corrosion at the clamp, messenger wire, or counterweight fitting reduces damping, detunes stiffness, and allows higher conductor vibration amplitudes under wind excitation.'
}]->(f);

MATCH (c:ComponentType {name: 'stockbridge_damper'}), (f:FailureMode {name: 'aeolian_vibration_fatigue'})
CREATE (c)-[:MITIGATES_FAILURE {
  mechanism: 'Healthy Stockbridge dampers dissipate energy from aeolian vibration and reduce conductor fatigue accumulation near clamps.'
}]->(f);

// ---------------------------------------------------------------------------
// 11. FAILURE MODE -> RISK (IMPACTS)
// ---------------------------------------------------------------------------

CREATE (r_cond_drop:Risk {
  risk_id: 'RISK-001',
  name: 'conductor_drop',
  risk_score: 0.95,
  consequence: 'Energised conductor falls to ground. Electrocution hazard to public. Forced sustained outage. Equipment damage cascade.',
  uncertainty: 0.3,
  source: 'domain_knowledge'
})

CREATE (r_outage:Risk {
  risk_id: 'RISK-002',
  name: 'forced_outage',
  risk_score: 0.70,
  consequence: 'Protection relay trips the line. Unplanned outage causing load shedding or re-dispatch costs. Customer minutes lost.',
  uncertainty: 0.2,
  source: 'domain_knowledge'
})

CREATE (r_bushfire:Risk {
  risk_id: 'RISK-003',
  name: 'bushfire_ignition',
  risk_score: 0.85,
  consequence: 'Ignition of vegetation in the transmission corridor. Potential for catastrophic wildfire in dry conditions. Legal and regulatory liability.',
  uncertainty: 0.4,
  source: 'domain_knowledge'
})

CREATE (r_dispatch:Risk {
  risk_id: 'RISK-004',
  name: 'maintenance_dispatch_failure',
  risk_score: 0.30,
  consequence: 'Incorrect tower identification delays emergency crew dispatch. Extended outage duration and potential safety impact.',
  uncertainty: 0.2,
  source: 'domain_knowledge'
})

CREATE (r_insulation_degrade:Risk {
  risk_id: 'RISK-005',
  name: 'progressive_insulation_degradation',
  risk_score: 0.60,
  consequence: 'Gradually increasing flashover probability. Increased maintenance frequency required. Reduced line reliability index.',
  uncertainty: 0.3,
  source: 'domain_knowledge'
});

CREATE (r_conductor_fatigue:Risk {
  risk_id: 'RISK-006',
  name: 'conductor_fatigue_accumulation',
  risk_score: 0.80,
  consequence: 'Cumulative strand fatigue near suspension hardware. May progress to strand breakage, clamp damage, and ultimately conductor-drop risk if not corrected.',
  uncertainty: 0.35,
  source: 'simulink_supported_domain_knowledge'
});

// Link failure modes to risks
MATCH (f:FailureMode {name: 'mechanical_failure'}), (r:Risk {risk_id: 'RISK-001'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'insulation_flashover'}), (r:Risk {risk_id: 'RISK-002'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'fire_hazard'}), (r:Risk {risk_id: 'RISK-003'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'clearance_violation'}), (r:Risk {risk_id: 'RISK-002'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'clearance_violation'}), (r:Risk {risk_id: 'RISK-003'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'tracking_erosion'}), (r:Risk {risk_id: 'RISK-005'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'brittle_fracture'}), (r:Risk {risk_id: 'RISK-001'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'asset_identification_loss'}), (r:Risk {risk_id: 'RISK-004'})
CREATE (f)-[:IMPACTS]->(r);

MATCH (f:FailureMode {name: 'aeolian_vibration_fatigue'}), (r:Risk {risk_id: 'RISK-006'})
CREATE (f)-[:IMPACTS]->(r);

// ---------------------------------------------------------------------------
// 12. ENVIRONMENT CONTEXTS (lateral influence on defect probability)
// ---------------------------------------------------------------------------

CREATE (env_coastal:Environment {
  environment_id: 'ENV-COASTAL',
  name: 'Coastal / High Salinity',
  humidity: 'high',
  salinity: 'high',
  pollution_index: 'heavy',
  description: 'Transmission corridors within 50 km of coastline. Salt spray accelerates corrosion of galvanized hardware and increases contamination flashover risk on insulators.'
})

CREATE (env_arid:Environment {
  environment_id: 'ENV-ARID',
  name: 'Semi-arid / Caatinga',
  humidity: 'low_to_moderate',
  salinity: 'low',
  pollution_index: 'light',
  description: 'Northeast Brazil semi-arid biome. Intense UV degrades polymer materials. Dry seasons increase bushfire risk. Bird nesting common due to limited tall vegetation.'
})

CREATE (env_industrial:Environment {
  environment_id: 'ENV-INDUSTRIAL',
  name: 'Industrial / Urban',
  humidity: 'variable',
  salinity: 'low',
  pollution_index: 'heavy',
  description: 'Proximity to industrial emissions (cement, chemical). Conductive deposits on insulator surfaces increase leakage current and flashover probability.'
});

// Environment increases risk of certain defects
MATCH (env:Environment {environment_id: 'ENV-COASTAL'}), (d:DefectType {name: 'corrosion'})
CREATE (env)-[:INCREASES_RISK {factor: 3.0, mechanism: 'Salt spray attacks zinc galvanising layer, exposing base steel to oxidation'}]->(d);

MATCH (env:Environment {environment_id: 'ENV-COASTAL'}), (d:DefectType {name: 'missing_cap'})
CREATE (env)-[:INCREASES_RISK {factor: 1.5, mechanism: 'Salt contamination increases leakage current, thermal stress on glass discs'}]->(d);

MATCH (env:Environment {environment_id: 'ENV-ARID'}), (d:DefectType {name: 'housing_tear'})
CREATE (env)-[:INCREASES_RISK {factor: 2.0, mechanism: 'Intense UV radiation degrades silicone rubber housing elasticity'}]->(d);

MATCH (env:Environment {environment_id: 'ENV-ARID'}), (d:DefectType {name: 'bird_nest'})
CREATE (env)-[:INCREASES_RISK {factor: 2.5, mechanism: 'Limited tall vegetation drives birds to nest on tower structures'}]->(d);

MATCH (env:Environment {environment_id: 'ENV-INDUSTRIAL'}), (d:DefectType {name: 'corrosion'})
CREATE (env)-[:INCREASES_RISK {factor: 2.0, mechanism: 'Industrial pollutants (SO2, NOx) in combination with moisture form corrosive acids'}]->(d);

// ---------------------------------------------------------------------------
// 13. STANDARDS (knowledge backbone for compliance)
// ---------------------------------------------------------------------------

CREATE (std_iec61284:Standard {
  name: 'IEC 61284',
  type: 'international',
  description: 'Overhead lines - Requirements and tests for fittings. Covers mechanical and electrical requirements for clamps, shackles, links, and other hardware.'
})

CREATE (std_iec61109:Standard {
  name: 'IEC 61109',
  type: 'international',
  description: 'Insulators for overhead lines - Composite suspension and tension insulators for AC systems. Specifies design tests, type tests, and sample tests for polymer insulators.'
})

CREATE (std_iec60383:Standard {
  name: 'IEC 60383',
  type: 'international',
  description: 'Insulators for overhead lines with nominal voltage above 1000V. Part 1 covers ceramic/glass insulator units, including toughened glass disc insulators.'
})

CREATE (std_iec60815:Standard {
  name: 'IEC 60815',
  type: 'international',
  description: 'Selection and dimensioning of high-voltage insulators intended for use in polluted conditions. Defines site pollution severity and minimum creepage distances.'
})

CREATE (std_ieee957:Standard {
  name: 'IEEE 957',
  type: 'international',
  description: 'Guide for cleaning insulators. Provides methods for live-line and de-energised insulator washing to maintain dielectric performance under contamination.'
})

CREATE (std_nesc:Standard {
  name: 'IEEE C2 (NESC)',
  type: 'national',
  description: 'National Electrical Safety Code. Defines minimum clearances, strength requirements, and grounding practices for overhead transmission lines.'
})

CREATE (std_abnt5422:Standard {
  name: 'ABNT NBR 5422',
  type: 'national',
  description: 'Brazilian standard for design of overhead transmission lines. Covers conductor clearances, mechanical loading, and tower design for Brazilian climatic conditions.'
});

// Components conform to standards
MATCH (c:ComponentType), (s:Standard {name: 'IEC 61284'})
WHERE c.supercategory = 'suporte'
MERGE (c)-[:CONFORMS_TO]->(s);

MATCH (c:ComponentType), (s:Standard {name: 'IEC 61284'})
WHERE c.name IN ['stockbridge_damper', 'spiral_damper', 'spacer', 'vari-grip', 'yoke']
MERGE (c)-[:CONFORMS_TO]->(s);

MATCH (c:ComponentType {name: 'polymer_insulator'}), (s:Standard {name: 'IEC 61109'})
MERGE (c)-[:CONFORMS_TO]->(s);

MATCH (c:ComponentType {name: 'glass_insulator'}), (s:Standard {name: 'IEC 60383'})
MERGE (c)-[:CONFORMS_TO]->(s);

MATCH (c:ComponentType), (s:Standard {name: 'IEC 60815'})
WHERE c.name IN ['polymer_insulator', 'glass_insulator']
MERGE (c)-[:CONFORMS_TO]->(s);

// Standards mitigate failure modes
MATCH (s:Standard {name: 'IEC 60815'}), (f:FailureMode {name: 'insulation_flashover'})
CREATE (s)-[:MITIGATES {mechanism: 'Proper creepage distance selection per pollution severity class prevents contamination flashover'}]->(f);

MATCH (s:Standard {name: 'IEEE 957'}), (f:FailureMode {name: 'insulation_flashover'})
CREATE (s)-[:MITIGATES {mechanism: 'Regular insulator cleaning maintains dielectric performance under polluted conditions'}]->(f);

MATCH (s:Standard {name: 'IEC 61284'}), (f:FailureMode {name: 'mechanical_failure'})
CREATE (s)-[:MITIGATES {mechanism: 'Hardware designed and tested to specified mechanical loading with safety factors per IEC requirements'}]->(f);

MATCH (s:Standard {name: 'IEEE C2 (NESC)'}), (f:FailureMode {name: 'clearance_violation'})
CREATE (s)-[:MITIGATES {mechanism: 'Minimum electrical clearance requirements prevent flashover under expected overvoltage conditions'}]->(f);

// ---------------------------------------------------------------------------
// 14. MAINTENANCE ACTIONS (decision support output)
// ---------------------------------------------------------------------------

CREATE (ma_monitor:MaintenanceAction {
  name: 'visual_monitoring',
  urgency: 'routine',
  description: 'Continue monitoring during scheduled inspection cycles. Capture UAV images for trend analysis. No immediate physical intervention required.',
  typical_timeframe: 'next_scheduled_inspection',
  estimated_cost_category: 'low'
})

CREATE (ma_clean:MaintenanceAction {
  name: 'insulator_cleaning',
  urgency: 'scheduled',
  description: 'Live-line or de-energised washing of insulator strings to remove contamination deposits. Restores leakage distance and reduces flashover probability.',
  typical_timeframe: 'within_3_months',
  estimated_cost_category: 'low'
})

CREATE (ma_replace_disc:MaintenanceAction {
  name: 'insulator_disc_replacement',
  urgency: 'scheduled',
  description: 'Replace shattered or missing glass insulator discs. Requires de-energised work or live-line hot-stick technique depending on number of remaining good units.',
  typical_timeframe: 'within_1_month',
  estimated_cost_category: 'medium'
})

CREATE (ma_replace_hardware:MaintenanceAction {
  name: 'hardware_replacement',
  urgency: 'scheduled',
  description: 'Replace corroded shackles, clamps, or other metallic fittings. Typically requires a planned outage for the affected circuit.',
  typical_timeframe: 'within_3_months',
  estimated_cost_category: 'medium'
})

CREATE (ma_replace_insulator:MaintenanceAction {
  name: 'insulator_string_replacement',
  urgency: 'priority',
  description: 'Replace the entire polymer insulator string due to housing damage or tracking. Critical to prevent brittle fracture. Requires planned outage.',
  typical_timeframe: 'within_2_weeks',
  estimated_cost_category: 'high'
})

CREATE (ma_nest_removal:MaintenanceAction {
  name: 'bird_nest_removal',
  urgency: 'priority',
  description: 'Remove bird nesting material from tower hardware. Install bird deterrent devices (spikes, guards). May require environmental compliance check for protected species.',
  typical_timeframe: 'within_1_month',
  estimated_cost_category: 'low'
})

CREATE (ma_repaint:MaintenanceAction {
  name: 'id_plate_repaint',
  urgency: 'routine',
  description: 'Repaint or replace the tower identification plate to restore legibility. Low urgency but important for asset management integrity.',
  typical_timeframe: 'within_6_months',
  estimated_cost_category: 'low'
})

CREATE (ma_emergency:MaintenanceAction {
  name: 'emergency_intervention',
  urgency: 'emergency',
  description: 'Immediate de-energisation and crew dispatch. Applicable when imminent conductor drop, active fire risk, or critical structural failure is identified.',
  typical_timeframe: 'within_24_hours',
  estimated_cost_category: 'very_high'
});

CREATE (wo_stockbridge_inspect:WorkOrderTemplate {
  template_id: 'WO-STOCKBRIDGE-INSPECT',
  title: 'Inspect Stockbridge damper and adjacent conductor clamp',
  description: 'Field crew should inspect damper clamp, messenger wire, counterweights, bolts, cotter pins, and adjacent conductor strands for corrosion, looseness, detuning, or fatigue damage.',
  trigger_condition: 'visual corrosion or elevated vibration/fatigue simulation features',
  required_inputs: ['vlm_component_prediction', 'vlm_defect_prediction', 'simulink_risk_score', 'fatigue_damage_index', 'image_reference'],
  output_fields: ['asset_id', 'component', 'defect', 'severity', 'risk_score', 'recommended_action', 'crew_instruction', 'evidence_trace']
})

CREATE (wo_hardware_replace:WorkOrderTemplate {
  template_id: 'WO-HARDWARE-REPLACE',
  title: 'Replace or refurbish corroded line hardware',
  description: 'Plan replacement or refurbishment of corroded metallic fittings before pitting or section loss compromises the mechanical safety factor.',
  trigger_condition: 'moderate corrosion or ontology action hardware_replacement',
  required_inputs: ['component', 'defect', 'severity', 'risk_score', 'applicable_standard'],
  output_fields: ['outage_requirement', 'crew_type', 'material_list', 'target_timeframe', 'safety_notes']
})

CREATE (wo_emergency:WorkOrderTemplate {
  template_id: 'WO-EMERGENCY-INTERVENTION',
  title: 'Emergency inspection and intervention',
  description: 'Escalate for urgent field inspection or de-energisation when severe defect evidence or high risk score indicates imminent safety or outage risk.',
  trigger_condition: 'severe defect, emergency_intervention action, or high fused risk score',
  required_inputs: ['component', 'defect', 'failure_mode', 'risk', 'confidence', 'evidence_trace'],
  output_fields: ['dispatch_priority', 'switching_required', 'crew_instruction', 'public_safety_note']
});

MATCH (w:WorkOrderTemplate {template_id: 'WO-STOCKBRIDGE-INSPECT'})
MATCH (c:ComponentType {name: 'stockbridge_damper'})
CREATE (w)-[:APPLIES_TO]->(c);

MATCH (w:WorkOrderTemplate {template_id: 'WO-HARDWARE-REPLACE'})
MATCH (m:MaintenanceAction {name: 'hardware_replacement'})
CREATE (w)-[:IMPLEMENTS]->(m);

MATCH (w:WorkOrderTemplate {template_id: 'WO-STOCKBRIDGE-INSPECT'})
MATCH (m:MaintenanceAction {name: 'visual_monitoring'})
CREATE (w)-[:IMPLEMENTS]->(m);

MATCH (w:WorkOrderTemplate {template_id: 'WO-EMERGENCY-INTERVENTION'})
MATCH (m:MaintenanceAction {name: 'emergency_intervention'})
CREATE (w)-[:IMPLEMENTS]->(m);



// ---------------------------------------------------------------------------
// 15. DEFECT + SEVERITY -> MAINTENANCE ACTION (REQUIRES relationships)
//     The core decision-support logic.
//
//     INVARIANT: the maintenance action is determined by the (defect,
//     severity) PAIR, never by the defect or the severity alone - e.g. at
//     moderate severity, corrosion requires hardware_replacement while
//     missing_cap requires insulator_disc_replacement. The severity condition
//     is stored as the mandatory `when_severity` property on each REQUIRES
//     edge, and there is EXACTLY ONE REQUIRES edge per (defect, when_severity).
//     Every query that retrieves an action for an assessed severity MUST
//     filter on it:
//
//       MATCH (d:DefectType {name: $defect})-[req:REQUIRES]->(ma)
//       WHERE req.when_severity = $severity_level
//
//     Matching REQUIRES without this filter returns the whole severity-indexed
//     rule table (one action per level), not a single recommendation.
// ---------------------------------------------------------------------------

// --- Corrosion ---
// Minor corrosion -> monitor
MATCH (d:DefectType {name: 'corrosion'}), (s:Severity {level: 1}), (m:MaintenanceAction {name: 'visual_monitoring'})
CREATE (d)-[:REQUIRES {when_severity: 1, rationale: 'Early-stage surface oxidation within normal weathering. Track progression rate via UAV image comparison.'}]->(m);

// Moderate corrosion -> schedule hardware replacement
MATCH (d:DefectType {name: 'corrosion'}), (s:Severity {level: 2}), (m:MaintenanceAction {name: 'hardware_replacement'})
CREATE (d)-[:REQUIRES {when_severity: 2, rationale: 'Pitting corrosion reduces cross-sectional area. Replace before safety factor drops below design minimum.'}]->(m);

// Severe corrosion -> emergency
MATCH (d:DefectType {name: 'corrosion'}), (s:Severity {level: 3}), (m:MaintenanceAction {name: 'emergency_intervention'})
CREATE (d)-[:REQUIRES {when_severity: 3, rationale: 'Extensive material loss. Immediate risk of hardware fracture under normal loading or transient (ice/wind).'}]->(m);

// --- Missing Cap ---
// Moderate (1 cap) -> replace disc
MATCH (d:DefectType {name: 'missing_cap'}), (m:MaintenanceAction {name: 'insulator_disc_replacement'})
CREATE (d)-[:REQUIRES {when_severity: 2, rationale: 'Single missing disc: adequate remaining withstand for dry conditions but reduced margin under contamination/rain.'}]->(m);

// Severe (multiple caps) -> emergency + replace
MATCH (d:DefectType {name: 'missing_cap'}), (m:MaintenanceAction {name: 'emergency_intervention'})
CREATE (d)-[:REQUIRES {when_severity: 3, rationale: 'Multiple missing discs: flashover likely under wet contaminated conditions. Risk of sustained fault.'}]->(m);

// --- Bird Nest ---
// Moderate -> scheduled nest removal
MATCH (d:DefectType {name: 'bird_nest'}), (m:MaintenanceAction {name: 'bird_nest_removal'})
CREATE (d)-[:REQUIRES {when_severity: 2, rationale: 'Nest not yet bridging clearance but growing. Remove and install deterrents before fire season.'}]->(m);

// Severe -> emergency
MATCH (d:DefectType {name: 'bird_nest'}), (m:MaintenanceAction {name: 'emergency_intervention'})
CREATE (d)-[:REQUIRES {when_severity: 3, rationale: 'Large nest bridging live-to-ground clearance. Immediate flashover and fire risk, especially in dry conditions.'}]->(m);

// --- Housing Tear ---
// Moderate -> replace insulator string
MATCH (d:DefectType {name: 'housing_tear'}), (m:MaintenanceAction {name: 'insulator_string_replacement'})
CREATE (d)-[:REQUIRES {when_severity: 2, rationale: 'Housing breach risks moisture ingress to GRP core. Replace proactively to avoid catastrophic brittle fracture.'}]->(m);

// Severe -> emergency
MATCH (d:DefectType {name: 'housing_tear'}), (m:MaintenanceAction {name: 'emergency_intervention'})
CREATE (d)-[:REQUIRES {when_severity: 3, rationale: 'Core rod likely compromised. Brittle fracture can occur without warning under normal mechanical load.'}]->(m);

// --- Peeling Paint ---
// Minor -> monitor
MATCH (d:DefectType {name: 'peeling_paint'}), (m:MaintenanceAction {name: 'visual_monitoring'})
CREATE (d)-[:REQUIRES {when_severity: 1, rationale: 'Number still legible. Schedule repaint at next routine tower maintenance.'}]->(m);

// Moderate -> repaint
MATCH (d:DefectType {name: 'peeling_paint'}), (m:MaintenanceAction {name: 'id_plate_repaint'})
CREATE (d)-[:REQUIRES {when_severity: 2, rationale: 'Tower number becoming illegible. Repaint to maintain asset register accuracy and emergency dispatch capability.'}]->(m);

// ---------------------------------------------------------------------------
// 16. SUMMARY: Full causal chain is now traversable
//
//   Image -[HAS_COMPONENT]-> ComponentType
//         -[HAS_DEFECT]-> DefectType
//         -[HAS_OBSERVATION]-> Observation
//
//   ComponentType -[PART_OF]-> Asset
//                -[ATTACHES_TO]-> ComponentType
//                -[CONFORMS_TO]-> Standard
//
//   DefectType -[AFFECTS]-> ComponentType
//             -[HAS_SEVERITY {condition}]-> Severity        (levels 1-3 only)
//             -[LEADS_TO]-> FailureMode
//             -[REQUIRES {when_severity, rationale}]-> MaintenanceAction
//                 (exactly one action per (defect, when_severity) pair;
//                  always filter on when_severity when resolving an action)
//
//   Severity -[ESCALATES_TO]-> Severity   (ordinal chain 0 -> 1 -> 2 -> 3)
//
//   FailureMode -[IMPACTS]-> Risk
//
//   Environment -[INCREASES_RISK]-> DefectType
//
//   Standard -[MITIGATES]-> FailureMode
//
//   Observation -[MENTIONS]-> DefectType
//              -[MENTIONS]-> ComponentType
//
// ---------------------------------------------------------------------------
