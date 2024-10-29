/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Nom du programme : filter
/* Objective : 
Filter extraction tables to restrict the population to valid beneficiares 
(obtained using the clean_ben SAS file)

Restric the extract to a specfic period

/* Tables : 

input tables

ben_tot : table des bénéficaires avec des ben_idt_ano valides pour l'étude
als_atc_09_22 : les demandes de remboursement pour MS-DMT sur les années 2009 -> 2022
als_ald_09_22 : LTD benefits with a G35 ICD-10 code
als_pmsi_09_22 : MS-HOSP with a G35 ICD-10 code

output tables

extraction_dmt : MS-DMT 
extraction_ltd : MS-LTD 
extraction_hosp : MS-HOSP

/*****************************************************************************/





/*

Fonctions

*/


/*

Fonction qui load les tables de sasdata1 dans le work. Les tables des macro de macro_file
sont appelés depuis le work

*/

%macro to_work(TABLEIN=, TABLEOUT=);
		 
		proc sql;
		create table work.&TABLEOUT as
		select *
		from sasdata1.&TABLEIN;
		quit;

				;
	/*** Fin de la boucle ***/
%mend to_work;

%to_work(tablein=ms_atc_06_23, tableout=ms_atc_06_23);
%to_work(tablein=ms_pmsi_06_23, tableout=ms_pmsi_06_23);
%to_work(tablein=nmosd_pmsi_06_23, tableout=nmosd_pmsi_06_23);
%to_work(tablein=ms_ald_09_23, tableout=ms_ald_09_23);



proc sql;
		create table work.ms_atc_06_23 as
		select a.*, b.ben_idt_ano
		from work.ms_atc_06_23 a left join work.ben_tot b 
on a.ben_nir_psa = b.ben_nir_psa;
		quit;

		
proc sql;
		create table work.ms_pmsi_06_23 as
		select a.*, b.ben_idt_ano
		from work.ms_pmsi_06_23 a left join work.ben_tot b 
on a.ben_nir_psa = b.ben_nir_psa;
		quit;

		
proc sql;
		create table work.ms_ald_09_23 as
		select a.*, b.ben_idt_ano
		from work.ms_ald_09_23 a left join work.ben_tot b 
on a.ben_nir_psa = b.ben_nir_psa;
		quit;


/* 

on eneleve les données d'extraction qui correspondent à des ben_idt_ano
non valides dans le cadre de notre étude

*/


%macro inner_join_(table_out=,table_one=, table_two=);

	proc sql;
	create table work.&table_out as
	select a.*, b.ben_idt_ano
	from work.&table_one a inner join work.&table_two b
	on a.ben_nir_psa = b.ben_nir_psa

;
%mend inner_join_;


%inner_join_(table_out = ms_atc_06_23,
			table_one = ms_atc_06_23,
			table_two = ben_tot);
%inner_join_(table_out = ms_pmsi_06_23,
			table_one = ms_pmsi_06_23,
			table_two = ben_tot);
%inner_join_(table_out = ms_ald_09_23,
			table_one = ms_ald_09_23,
			table_two = ben_tot);

%inner_join_(table_out = nmosd_pmsi_06_23,
			table_one = nmosd_pmsi_06_23,
			table_two = ben_tot);

proc sort data=work.ms_atc_06_23 out=work.ms_atc_06_23 nodupkey;
by ben_idt_ano exe_soi_dtd;
run;

proc sort data=work.ms_pmsi_06_23 out=work.ms_pmsi_06_23 nodupkey;
by ben_idt_ano exe_soi_dtd;
run;

proc sort data=work.ms_ald_09_23 out=work.ms_ald_09_23 nodupkey;
by ben_idt_ano exe_soi_dtd;
run;



/*

Specification de la periode d'interet sur laquelle on souhaite identifier 
des cas inicidents de la maladie. Les dates suffixees prev renseignent la fenetre
de temps utiliser pour exclure les cas prevelents. Les dates suffixees inc renseignent
la fenetre de temps sur laquelle les cas incidents seront identifies

*/

/*

parametres d'entree

*/

%let dtd_inc = 01011950;
%let dtf_inc = 31122024;

/* 

on filtre les donnees sur la date de soins afin d'avoir les 
donnees sur nos deux fenetres d'interets, la fenetre
de prevalence et la fenetre d'incidnece

*/


%macro filter_date(TABLEOUT=, TABLEIN=, DTD_FILTER=, DTF_FILTER=);
		 
/* on ajoute a chaque ben_idt_ano tous les ben_nir_psa possibles dans ir_ben_r */

		%let soi_dtd_filter= %sysfunc(inputn(&DTD_FILTER,DDMMYY8),date9);
		%let soi_dtf_filter= %sysfunc(inputn(&DTF_FILTER,DDMMYY8),date9);

		proc sql;
		create table work.&TABLEOUT as
		select *
		from work.&TABLEIN
		where exe_soi_dtd between "&soi_dtd_filter:0:0:0"dt and "&soi_dtf_filter:0:0:0"dt;
		quit;

				;
	/*** Fin de la boucle ***/
%mend filter_date;


%filter_date(TABLEOUT=extraction_hosp,
			 TABLEIN=ms_pmsi_06_23,
			 DTD_FILTER=&dtd_inc,
			 DTF_FILTER=&dtf_inc);

%filter_date(TABLEOUT=extraction_ltd,
			 TABLEIN=ms_ald_09_23,
			 DTD_FILTER=&dtd_inc,
			 DTF_FILTER=&dtf_inc);

%filter_date(TABLEOUT=extraction_dmt,
			 TABLEIN=ms_atc_06_23,
			 DTD_FILTER=&dtd_inc,
			 DTF_FILTER=&dtf_inc);

