
/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Nom du programme : merge
/* Objective : 
Merge table from different data sources(hosp, dmt, ltd).
It will allow to compute the index date by taking the minimum date between 
hosp, ltd, and dmt tables for each individual

/* Tables : 

input tables

extraction_ltd
extraction_hosp
extraction_dmt

output tables

extraction_hosp_ltd_dmt

/*****************************************************************************/





/*

Requête qui concatène les extractions des différentes sources
La variable atc_source renseigne sur le type de source:
* 1 si la source est une demande de remboursement (ER_PRS_F du DCIR)
* 0 si elle provient d'une hospitalistion (T_MCO_ du PMSI)
* 2 si elle provient d'une ALD (IR_IMB_ du DCIR)
 
*/



proc sql;

   create table work.extraction_hosp as

      select ben_idt_ano,
			 exe_soi_dtd

	  from work.extraction_hosp

quit;

proc sql;

   create table work.extraction_dmt as

      select ben_idt_ano,
			 exe_soi_dtd

	  from work.extraction_dmt

quit;

proc sql;

   create table work.extraction_ltd as

      select ben_idt_ano,
			 exe_soi_dtd

	  from work.extraction_ltd

quit;


/*

On fusionnes les extractions pour les années avant la période d'intérêt.

*/

proc sql;
   create table work.extraction_hosp_ltd_dmt as

      select ben_idt_ano,
			 exe_soi_dtd,
			 'hosp' as source 
	  from work.extraction_hosp

      union

      select ben_idt_ano,
			 exe_soi_dtd,
			 'dmt' as source
      from work.extraction_dmt

	  union

	  select ben_idt_ano,
			 exe_soi_dtd,
			 'ltd' as source

      from work.extraction_ltd;
quit;
