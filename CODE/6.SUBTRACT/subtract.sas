

/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Nom du programme : subtract
/* Objective : 
Create the table that contains sensitive and specific MS cases. Add the socio-demographic
variables for each definition, and clean accordingly.

Refer to publication of sensitive and specific definition.

/* Tables : 

input tables

ms_prob
ms_highly_prob
ben_tot

output tables

ms_sensitive
ms_specific

/*****************************************************************************/



proc sql;
create table work.ms_sensitive as
select *
from work.ms_prob
union
select *
from work.ms_highly_prob
;
quit;

proc sql;
create table work.ms_specific as
select *
from work.ms_highly_prob
;
quit;




/* we drop duplicates because there might be several lines for one ben_idt_ano in ir_ben_r 
il est ausssi possible que l on ait identifie 2 ben_nir_psa qui correspondent en fait à la même personne
*/

proc sort data=work.ms_sensitive out=work.ms_sensitive nodupkey;
    by ben_idt_ano;
run;

proc sort data=work.ms_specific out=work.ms_specific nodupkey;
    by ben_idt_ano;
run;


/* we add the socio demographic variables (age and sex) to our table */


%macro age_at_index(TABLE=);
		 
/* on ajoute a chaque ben_idt_ano tous les ben_nir_psa possibles dans ir_ben_r */
		
proc sql;
	create table work.&TABLE as
	select a.ben_idt_ano,
					a.exe_soi_dtd,
					b.ben_nai_ann,
					b.ben_nai_moi,
					b.ben_sex_cod-1 as sex
					
	from work.&TABLE a
		 left join work.ben_tot b on a.ben_idt_ano = b.ben_idt_ano

		 ;
	quit;

	
	proc sql;
    update work.&TABLE
    set BEN_NAI_MOI = '06'
    where BEN_NAI_MOI not in ('01','02','03','04','05','06','07','08','09','10','11','12');
	quit;


	proc sql;
		create table work.&TABLE as

		select *,
				dhms(input(b.ben_nai_moi || '/' || '01' || '/' || b.ben_nai_ann, mmddyy10.),0,0,0) format = datetime20. as DAT_NAI_SAS

		from work.&TABLE b
		;
	quit;
	/* on calcule l age a la prescription : difference entre exe_soi_dtd et la date de naissance */

	proc sql;
		create table work.&TABLE as

		select *,
				intck('day', datepart(b.dat_nai_sas), datepart(b.exe_soi_dtd))/365.25 as age_at_index
			
		from work.&TABLE b
		;
	quit;

	proc sort data=&TABLE out=&TABLE nodupkey;
	by ben_idt_ano;
	run;
				;
	/*** Fin de la boucle ***/
%mend age_at_index;


%age_at_index(TABLE=ms_sensitive);
%age_at_index(TABLE=ms_specific);

%macro pre_processing(TABLE=);

	proc sql;
	create table work.&TABLE as
	select *
	from work.&TABLE
	where age_at_index < 90;
	quit;


	data work.&TABLE;
	set work.&TABLE;
	retain sex;
	if missing(sex) then delete;
	run;


	proc sql;
	create table work.&TABLE as
	select *
	from work.&TABLE
	where BEN_NAI_ANN ^= '0000';
	quit;

;
	/*** Fin de la boucle ***/
%mend pre_processing;

%pre_processing(TABLE=ms_specific);
%pre_processing(TABLE=ms_sensitive);


proc sort data=work.ms_specific out=sasdata1.ms_specific nodupkey;
    by ben_idt_ano;
run;

proc sort data=work.ms_sensitive out=sasdata1.ms_sensitive nodupkey;
    by ben_idt_ano;
run;


/*

		Distribution of the number fo incident cases

*/

%macro DISTRIBUTION_INDEX(TABLE=, YEAR_MIN=, YEAR_MAX=, Y_MIN = , Y_MAX =);

proc sql;
    create table distribution_par_annee as
    select year(datepart(exe_soi_dtd)) as annee,
           count(*) as nombre_obs
    from work.&TABLE
    group by year(datepart(exe_soi_dtd))
    order by annee;
quit;

	proc sort data=work.distribution_par_annee out=work.distribution_par_annee nodupkey;
    by annee;
	run;

;

/* Création du graphique */

proc sgplot data=work.DISTRIBUTION_PAR_ANNEE;
    scatter x=annee y=nombre_obs / markerattrs=(symbol=circlefilled);
    xaxis label="Annees" values=(&YEAR_MIN to &YEAR_MAX by 1);
    yaxis label="Nombre de cas incidents" values=(&Y_MIN to &Y_MAX by 100);
run;
	/*** Fin de la boucle ***/
%mend DISTRIBUTION_INDEX;



proc sort data=ms_sensitive out=test nodupkey;
by ben_idt_ano;
run;

%DISTRIBUTION_INDEX(TABLE=test,
					YEAR_MIN = 2010,
					YEAR_MAX = 2021,
					Y_MIN = 0,
					Y_MAX = 10000);


%macro add_all_ben_nir_psa(TABLE=, TABLEIN=);
		 
/* on ajoute a chaque ben_idt_ano tous les ben_nir_psa possibles dans ir_ben_r */

		proc sql;

			create table work.&table as


			select a.ben_nir_psa as all_ben_nir_psa,
					a.ben_rng_gem,
					a.ben_cdi_nir,
					b.*

			from work.ben_tot a,
		 		work.&tablein b

			where a.ben_idt_ano = b.ben_idt_ano

				;
	/*** Fin de la boucle ***/
%mend add_all_ben_nir_psa;


%add_all_ben_nir_psa(table = ms_specific, tablein = ms_specific);
%add_all_ben_nir_psa(table = ms_sensitive, tablein = ms_sensitive);




%macro clean_ben_idt(TABLE=);
		 
/* on ajoute a chaque ben_idt_ano tous les ben_nir_psa possibles dans ir_ben_r */


		proc sql;
		    create table work.doublons_idt_ano as
		    select *
		    from &TABLE
		    group by all_ben_nir_psa, ben_rng_gem
		    having count(*) > 1;
		quit;

		proc sql;
		create table work.idt_to_keep as
		select *
		from work.doublons_idt_ano
		where BEN_CDI_NIR = '00';
		quit;

		proc sql;
		create table work.&TABLE as
		select *
		from work.&TABLE a left join work.doublons_idt_ano b
		on a.ben_idt_ano = b.ben_idt_ano
		where b.ben_idt_ano is null;
		quit;

		proc sql;
		create table work.&TABLE as
		select *
		from work.&TABLE 
		union 
		select *
		from work.idt_to_keep;
		quit; 

				;
	/*** Fin de la boucle ***/
%mend clean_ben_idt;


%clean_ben_idt(table = ms_specific);
%clean_ben_idt(table = ms_sensitive);



proc sort data=ms_sensitive out=test nodupkey;
by ben_idt_ano;
run;

%DISTRIBUTION_INDEX(TABLE=test,
					YEAR_MIN = 2010,
					YEAR_MAX = 2021,
					Y_MIN = 0,
					Y_MAX = 10000);



proc sql;
create table work.ms_specific as
select a.*, b.dcd_dte
from work.ms_specific a left join sasdata1.all_dead b
on a.ben_idt_ano = b.ben_idt_ano;
quit;

proc sql;
create table work.ms_sensitive as
select a.*, b.dcd_dte
from work.ms_sensitive a left join sasdata1.all_dead b
on a.ben_idt_ano = b.ben_idt_ano;
quit;



/*


SOURCE OF IDENTIFICATION 

*/


%macro source_identification(TABLE=);
		 
/* on ajoute a chaque ben_idt_ano tous les ben_nir_psa possibles dans ir_ben_r */


			
		proc sql;
		create table work.&TABLE as
		select a.*, b.EXE_SOI_DTD as DMT_EXE_DTD
		from sasdata1.&TABLE a left join work.extraction_dmt b
		on a.ben_idt_ano = b.ben_idt_ano;
		quit;


		data work.no_apd;
		    set work.&TABLE;
		    if cmiss(of dmt_exe_dtd) then delete;
		run;

		proc sql;
		create table work.&TABLE as
		select a.*, b.EXE_SOI_DTD as PMSI_EXE_DTD
		from work.&TABLE a left join work.extraction_hosp b
		on a.ben_idt_ano = b.ben_idt_ano;
		quit;

		proc sql;
		create table work.&TABLE as
		select a.*, b.EXE_SOI_DTD as ALD_EXE_DTD
		from work.&TABLE a left join work.extraction_ltd b
		on a.ben_idt_ano = b.ben_idt_ano;
		quit;				


				;
	/*** Fin de la boucle ***/
%mend source_identification;


%source_identification(table = ms_specific);
%source_identification(table = ms_sensitive);

