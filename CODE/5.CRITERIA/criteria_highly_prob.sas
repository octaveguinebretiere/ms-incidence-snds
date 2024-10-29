


/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Nom du programme : criteria_highly_prob
/* Objective : 
Create the table that contains highly probable MS cases (patients with at least on MS-LTD).
the exe_soit_dtd variable is now the index date (minimum between the 3 sources)

/* Tables : 

input tables

extraction_ltd
extraction_hosp_ldt_dmt

output tables

ms_highly_prob

/*****************************************************************************/




proc sql;

create table work.ms_highly_prob as
select ben_idt_ano, exe_soi_dtd
from work.extraction_ltd;

quit;

proc sql;
create table work.ms_highly_prob as
select a.*
from work.ms_highly_prob a left join work.nmosd_pmsi_06_23 b
on a.ben_idt_ano = b.ben_idt_ano
where b.ben_idt_ano is null;
quit;


proc sort data=work.ms_highly_prob out=work.ms_highly_prob nodupkey;
by ben_idt_ano;
run;

%macro add_index_date(IN=, VAR_ID=, VAR_DATE=);

/*

Adds a column min_exe_soi which is the earliest date in the table per individual.

*/
	
	proc sql;

		create table work.patient_ald_pmsi as
		select &VAR_ID , exe_soi_dtd as min_exe_soi
		from work.&IN
		group by &VAR_ID
		;

	quit;


	PROC SORT DATA = work.patient_ald_pmsi NODUP;
	 BY &VAR_ID;
	 RUN;

	proc sort data=work.patient_ald_pmsi;
	    by &VAR_ID descending min_exe_soi;
	run;

	data work.patient_ald_pmsi;
	    update work.patient_ald_pmsi (obs=0) work.patient_ald_pmsi;
	    by &VAR_ID;
	run;

	
	proc sql;

		create table work.&IN as
		select a.*, b.min_exe_soi
		from work.&IN a inner join work.patient_ald_pmsi b
		on a.&VAR_ID = b.&VAR_ID
		;

	quit;

;
%mend add_index_date;

%macro new_index_date(TABLEIN=, TABLEEXT=);
		 
/*

Macro that concatenates data from a table of beneficiearies : tablein
with aother table, usually of records : tableext and finds
the earliest date (new index date)

*/
		
	proc sql;
	create table work.atc_apd_first as
	select a.*
	from work.&TABLEEXT a inner join work.&TABLEIN b
	on a.ben_idt_ano = b.ben_idt_ano;
	quit;

	proc sql;
	create table work.&TABLEIN as
	select ben_idt_ano,
			exe_soi_dtd
	  from work.atc_apd_first

	  union

	  select ben_idt_ano,
			exe_soi_dtd

      from work.&TABLEIN;
	quit;

	%add_index_date(IN=&TABLEIN,
					VAR_ID=BEN_IDT_ANO,
					VAR_DATE=EXE_SOI_DTD);

	/* remove exe_soi_dtd and replace it with the new index date min_exe_soi */

	proc sort data=work.&TABLEIN out=work.&TABLEIN nodupkey;
	by ben_idt_ano;
	run;

	data work.&TABLEIN;
	  set work.&TABLEIN (drop=exe_soi_dtd);
	run;

	proc sql;
	create table work.&TABLEIN as
	select ben_idt_ano, min_exe_soi as exe_soi_dtd
	from work.&TABLEIN ;
	quit;

				;
	/*** Fin de la boucle ***/
%mend new_index_date;


%new_index_date(TABLEIN=ms_highly_prob, TABLEEXT=extraction_hosp_ltd_dmt);



proc sort data=work.ms_highly_prob out=sasdata1.ms_highly_prob nodupkey;
by ben_idt_ano;
run;
