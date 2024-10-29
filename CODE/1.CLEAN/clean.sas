/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Program name : clean_ben
/* Objective : 
build the table of pre-processed beneficiaries

-> Exclusion of same sex siblings in the beneficiaries table (a problem specific to the SNDS data: the unique identifier can not distringuish 
same sex siblings in the hospital data (PMSI))
-> Exclusion of individuals from a social security regimen which was included in 2012
(otherwise, excess of prevalent cases)
-> Discard patients with a fictive unique identifier

/* Tables : output table: ben_tot in the work library

/*****************************************************************************/





%macro clean_ben_idt(tablein= ,tableout=);
	
/*

Focntion qui à partir de ir_ben_r et ir_ben_arc, ne retient que les 
beneficiaires qui ne sont pas des jumeaux de meme sex et qui 
ont un NIR certifié et qui n'appartiennent pas aux regimes 
CPRP SNCF 04 CCAS RATP 05 ENIM 06 CANSSM 07 avant 2012 
car ces regimes ont ete ajoutes en 2012. Garder ces patients aurait
pour consequence d'inclure des cas prevalents.

*/

/*

Exclusion des regimes 

*/


	%let regimes = ('04', '05', '06', '07');
	
	%let soi_dtd_filter= %sysfunc(inputn(01012006,DDMMYY8),date9);
	%let soi_dtf_filter= %sysfunc(inputn(01012013,DDMMYY8),date9);

	
	proc sql;

		create table work.excl_reg as
		select ben_idt_ano
		from work.&tablein
		where rgm_grg_cod in &regimes 
		and ben_dte_ins between "&soi_dtd_filter:0:0:0"dt and "&soi_dtf_filter:0:0:0"dt; 

	proc sql;

		create table work.&tableout as
		select *
		from work.&tablein a 
		left join work.excl_reg b 
		on a.ben_idt_ano = b.ben_idt_ano
		where b.ben_idt_ano is null;

	quit;
	


/*

Exclusion des jumeaux de meme sex

*/

	
	proc sql;

	create table work.case_siblings as
	select *
	from work.&tableout
	group by ben_nir_psa having count(distinct ben_rng_gem)>1;

	quit;

	proc sort data=work.case_siblings out=work.case_siblings_sorted nodupkey;
		by ben_idt_ano;
	run;


	/* Check for regime change among individuals with a unique ben_nir_psa and multiple ben_rng_gem */

	
	proc sql;

		create table work.case_siblings_sorted as
		select a.ben_nir_psa as all_ben_nir_psa,
				   a.ben_rng_gem,
				   a.org_aff_ben,
				   c.org_grg_cod,
				   b.*
		from oravue.ir_ben_r a,
		 		work.case_siblings_sorted b,
				oraval.IR_ORG_V c
		where a.ben_idt_ano = b.ben_idt_ano
				  and a.org_aff_ben = c.org_num
				;

/* identification of patients with a change in ben_rng_gem likely due to a regime change */

	proc sql;

		create table work.case_not_siblings as
		select *
		from work.case_siblings_sorted
		group by ben_idt_ano having count(distinct org_grg_cod)>1;

	quit;

	proc sort data=work.case_not_siblings out=work.case_not_siblings_sorted nodupkey;
		by ben_idt_ano;
	run;

/* individuals who changed their regime are removed from the dataframe of putative same sex siblings */

	proc sql;

		create table work.case_real_siblings as
		select *
		from work.case_siblings_sorted a 
		left join work.case_not_siblings_sorted b 
		on a.ben_idt_ano = b.ben_idt_ano
		where b.ben_idt_ano is null;

	quit;

	proc sql;

		create table work.&tableout as
		select *
		from work.&tableout a 
		left join work.case_real_siblings b 
		on a.ben_idt_ano = b.ben_idt_ano
		where b.ben_idt_ano is null;

	quit;

/*
Exclusion des NIR non certifies
*/

/*
	proc sql;

		create table work.&tableout as
		select *
		from work.&tablein
		where BEN_CDI_NIR = '00';

	quit;
*/

	proc sort data=work.&tableout out=work.&tableout nodupkey;
		by ben_idt_ano;
	run;

	
%mend clean_ben_idt;


/*

On concatene les deux tables beneficiaires 

*/

proc sql;

create table work.ben_tot as
		select BEN_NIR_PSA,
			   BEN_RNG_GEM,
			   BEN_IDT_ANO,
			   BEN_CDI_NIR,
			   org_aff_ben,
			   ben_nai_ann,
			   ben_nai_moi,
			   ben_sex_cod,
			   ben_res_dpt,
			   ben_dcd_dte,
			   substr(org_aff_ben, 1, 2) as rgm_grg_cod,
			   ben_dte_ins,
               ben_dte_maj

		from oravue.ir_ben_r
		union
		select BEN_NIR_PSA,
			   BEN_RNG_GEM,
			   BEN_IDT_ANO,
			   BEN_CDI_NIR,
			   org_aff_ben,
			   ben_nai_ann,
			   ben_nai_moi,
			   ben_sex_cod,
			   ben_res_dpt,
			   ben_dcd_dte,
			   substr(org_aff_ben, 1, 2) as rgm_grg_cod,
			   ben_dte_ins,
               ben_dte_maj

		from oravue.ir_ben_r_arc;

quit;


%clean_ben_idt(tablein = ben_tot, tableout = ben_tot);


