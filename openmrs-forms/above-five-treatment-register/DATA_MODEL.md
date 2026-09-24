# ABOVE FIVE (GENERAL) TREATMENT REGISTER — Data Model

Source: `source-register.csv` (Sierra Leone HMIS outpatient/morbidity register).

This register is a **paper register**: one row per patient visit, with tallies in condition
columns. For OpenMRS we model it as a **per-patient encounter form** — one encounter per
patient visit, recording the ticked morbidities as observations grouped by register section.

## Facility / Visit header

| Field | Notes |
|---|---|
| Facility name & type | free text |
| Ownership | Public / Private / Faithbase |
| Chiefdom / Zone | free text |
| Year / Month | period |
| Service point | In Facility / Outreach |

## Patient identifiers

| Register column | Field | Type |
|---|---|---|
| S No. | (row number, not stored) | — |
| Reg. No. | Registration number | text |
| Date seen | Visit date | date |
| Date of onset | Onset date | date |
| Patient Name | Name | text |
| NIN | National ID | text |
| Age in Years | Age | number |
| Sex | Male / Female | choice |
| Address | Address | text |
| Marital Status | Single / Married / Divorced | choice |
| Occupation | Occupation | text |
| Type of Visit | New / Follow-up | choice |
| Category of Patient | Pregnant / Lactating / EVD survivor / Disabled / General | choice (multi?) |

## Morbidity sections

### MALARIA
Fever cases (suspected malaria), RDT (positive/negative), Microscopy (positive/negative),
treated with ACT (<24h / >24h), treated without ACT, Artesunate injection,
severe malaria treated with Artesunate (IV/IM & supp), treat with parenteral anti-malarial.

### EYE
Eye infection, eye condition (all types except infection).

### INFECTIOUS
Moderate malnutrition; **Notifiable Medical Conditions** (Severe Malnutrition, AFP,
AVHF, Cholera, Dysentery/Bloody diarrhoea, Measles, Rubella, Meningitis/Encephalitis,
Buruli Ulcer, Yellow Fever, Typhoid/Paratyphoid, Tetanus, Animal Bites);
AIDS; Pneumonia with cough/cold (with/without antibiotic); Chicken Pox;
Diarrhoea watery (treated at facility); Hepatitis (all types); Leprosy;
Severe pneumonia treated with oxygen; Diarrhoea with severe dehydration IV; Mumps;
Sepsis; Skin Infection; STI (PID, genital discharge, genital ulcer); TB;
UTI; Onchocerciasis; Schistosomiasis; Trachoma; Other infectious conditions.

### INTERNAL MEDICINE, NCD and MENTAL
Anaemia, Asthma, Sickle Cell, Cancer (all types), Liver disease,
Cardiovascular (all types), Chronic respiratory (asthma/COPD), Diabetes,
Epilepsy, Hypertension, Upper GI/Pancreatitis, Chronic liver/Cirrhosis,
Appendicitis, Ileus/Obstruction, Stroke, Heart Failure, Kidney disorders,
Mental disorder (all types), Other NCD conditions.

### SUSPECTED CANCER
Breast, Prostate, Cervical, Childhood, Lungs, Liver, Others.

### SUSPECTED AVHL/F/D (viral haemorrhagic fevers / filariasis?)
Lassa Fever, Marburg, Yellow Fever, Others, Suspected MPOX, Ebola,
Severe Malaria, PPH & APH, Worm Infestation, Chronic Diseases.

### ANAEMIA
Severe Malaria, PPH & APH, Worm Infestation, Chronic Diseases.

> Note: source register's ANAEMIA and AVHL/F/D column groups overlap; treat as flags
> conservatively and confirm intended grouping before importing to production.

### DENTAL CONDITION
Caries, Abscess, Fracture.

### SUSPECTED POISON
Food, Caustic Soda, Others.

### DIARRHOEA
With blood (ORS & Zinc), Without blood (ORS & Zinc), With severe dehydration.

### DISABILITY
Physical, Visual impairment, Hearing impairment, Speech and language,
Multiple, Intellectual.

### SURGICAL
Acute abdomen, Appendicitis, ENT disorder, Hernia, Hydrocele, Lymphoedema,
Oral and dental conditions, PUD, Wounds/Trauma (RTA / non-RTA), Burns,
Typhoid perforation, Haemorrhoids/Piles, Other surgical conditions.

### ALL OTHER MORBIDITIES
Free-form / catch-all for conditions not listed.
