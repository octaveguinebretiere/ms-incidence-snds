# MS Incidence Extraction in the SNDS

## Project overview

Multiple sclerosis (MS) is a chronic neurological condition that stands as the leading cause of non-traumatic neurological disability in young adults. Accurate identification of incident MS cases is essential to comprehending its epidemiology and monitoring evolving trends, especially given the recent changes in diagnostic criteria. Although the global prevalence of MS is on the rise, recent temporal trends in its incidence are less clear.

This project leverages the French National Health Data System (SNDS) to study the temporal trends in MS incidence. The SNDS provides several advantages:

1. Since 2009, it covers 99% of the French population. 
2. It contains comprehensive data on MS-related disease-modifying therapies, hospital discharge codes, and benefits for long-term illnesses associated with MS.

These strengths enable robust identification and offer high generalizability. However, studying MS incidence can be challenging due to the absence of direct access to patient medical records. Consequently, patients with primary progressive MS or "benign" MS, who may not undergo treatment or have long-term benefits, might remain unrecorded until a complication occurs that necessitates hospitalization or the prescription of a disease-modifying therapy. This project aims to refine methods to assess the accuracy of MS case recording within the database.


## Code organization

The SAS code is structured to follow a specific workflow to ensure accurate data processing and analysis. The key steps are outlined below, and the detailed flow is illustrated below.

![Data flow](DATA_FLOW_MS_SNDS.pdf)
