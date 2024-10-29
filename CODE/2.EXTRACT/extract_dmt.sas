
/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Program name : extract_dmt
/* Objective : 
extract disease modifying therapies from the pharmacy (local and hospital) tables  

-> the 06-08 and 09-23 periods are trackled separaterly since the table names changed

/* Tables : output table: ms_atc_06_23 in the sasdata1 library

/*****************************************************************************/




/*************************************************************************************************************/
/************   Sélectionner des demandes de prescription de riluzole dans les tables                  *******/
/************   de prestations et tables pharmacies reliés. Programme compatible                        *******/
/************   avec indexation par flux (par mois). Peut etre lancé sous SAS asyncrhone               *******/
/************   Destination fichier de sortie : sasdata1                                               *******/
/*************************************************************************************************************/

/*************************************************************************************************************/

%macro DCIR_AN1()
			/des='[TLT] Retourne la 1ère année hors archive de DCIR';
	%global dcir_an1;
%put DCIR TEST: &dcir_an1;
proc sql noprint;
	create table sasdata1._dcir_an1 as
		select Memname
			from dictionary.tables
				where Libname='ORAVUE' and Memname like 'ER\_PRS\_F\_%' escape '\';
	select put(input(max(scan(Memname,-1,'_')),4.)+1,z4.) into :DCIR_AN1
		from sasdata1._dcir_an1;
	drop table sasdata1._dcir_an1;
quit;

%mend DCIR_AN1;

%macro J9K(G,D)
			/des='[TLT] Jointure sur les 9 clés entre 2 tables de DCIR - DCT exclus';
		&G..DCT_ORD_NUM=&D..DCT_ORD_NUM AND
		&G..FLX_DIS_DTD=&D..FLX_DIS_DTD AND
		&G..FLX_EMT_ORD=&D..FLX_EMT_ORD AND
		&G..FLX_EMT_NUM=&D..FLX_EMT_NUM AND
		&G..FLX_EMT_TYP=&D..FLX_EMT_TYP AND
		&G..FLX_TRT_DTD=&D..FLX_TRT_DTD AND
		&G..ORG_CLE_NUM=&D..ORG_CLE_NUM AND 
		&G..PRS_ORD_NUM=&D..PRS_ORD_NUM	AND 
		&G..REM_TYP_AFF=&D..REM_TYP_AFF
%mend J9K;

%macro PRS_PHA(SOI_DTD_DDMMAAAA=, SOI_DTF_DDMMAAAA=, NB_MOIS_FLX=, TABLE=, REINIT=, CODE_ATC=)
			/des='[MB/TLT] Extraction DCIR depuis les tables ER_PRS_F et ER_PHA_F par itération sur les dates FLX_DIS_DTD';
	/** Macro Basée sur la méthode CQSLFMens de M. TLT **/
	%dcir_an1;

	%let soi_dtd= %sysfunc(inputn(&SOI_DTD_DDMMAAAA,DDMMYY8),date9);
	%let soi_dtf= %sysfunc(inputn(&SOI_DTF_DDMMAAAA,DDMMYY8),date9);

	%if &REINIT=YES %then
		%_eg_conditional_dropds(sasdata1.&table);

	/*** La boucle sur les nombres de mois de flux : Début***/
	%do nm=1 %to &NB_MOIS_FLX.;
		 
		%let FLX=%sysfunc(intnx(MONTH,"&soi_dtd"d,&nm),date9.);
		
		%put flx value: &flx;
		/** Est-ce que le FLX pointe sur une archive **/
		%if %sysevalf("&flx."d>"01JAN&dcir_an1."d) %then
			%let arc=;
		%else %if %substr(&flx,3,3)=JAN %then
			%let arc=_%eval(%substr(&flx,6,4)-1);
		%else %let arc=_%substr(&flx,6,4);
		%put ### Itération %sysfunc(sum(1,&nm),z2.) FLX=&FLX SOI_DTD=&soi_dtd SOI_DTF=&soi_dtf %sysfunc(datetime(),datetime.);
		%put annee archive : &arc;
		/** Est-ce que la table résultat existe? Si oui insérer, sinon créer **/
		proc sql;

			%if %sysfunc(exist(sasdata1.&table.))=0 %then
				%do;
					create table sasdata1.&table as
				%end;
			%else
				%do;
					insert into sasdata1.&table
				%end;

			select distinct prs.ben_nir_psa,
				prs.ben_rng_gem,
				prs.exe_soi_dtd,
				atc.PHA_ATC_CLA

			from 
				oravue.er_prs_f&arc prs inner join oravue.er_pha_f&arc pha on %j9k(prs,pha),
				oravue.ir_pha_r atc

			where

				prs.exe_soi_dtd between "&soi_dtd:0:0:0"dt and "&soi_dtf:0:0:0"dt
				and atc.PHA_CIP_C13 = pha.PHA_PRS_C13
				and substr(atc.PHA_ATC_CLA,1,7) in &CODE_ATC
				and prs.FLX_DIS_DTD="&FLX:0:0:0"dt;
	%end;

	/*** Fin de la boucle ***/
%mend PRS_PHA;


%let dtd = 31122007;
%let dtf = 31122024;


%let out_file_name = ms_atc_09_23;

/*** Exécution de la macro ***/

/*

attention, il convient de modifier la taille du caractere dans substr si la longueur du code 
ATC est amenee a changer

*/

%PRS_PHA(SOI_DTD_DDMMAAAA=&dtd,
			SOI_DTF_DDMMAAAA=&dtf,
			NB_MOIS_FLX=216,
			TABLE=&out_file_name,
			REINIT=YES,
			CODE_ATC=('L03AB07','L03AB08','L03AB13','L03AX13',
					  'L04AA23', 'L04AA27', 'L04AA31', 'L04AA36',
						'L04AA40', 'L04AA50', 'L04AA52', 'L04AX07',
						'L04AX09', 'N07XX07', 'N07XX09'));


/*************************************************************************************************************/
/************   Sélectionner des demandes de prescription de riluzole dans les tables                  *******/
/************   de prestations et tables pharmacies reliés. Programme compatible                        *******/
/************   avec indexation par flux (par mois). Peut etre lancé sous SAS asyncrhone               *******/
/************   Destination fichier de sortie : sasdata1                                               *******/
/*************************************************************************************************************/

/*************************************************************************************************************/

%macro DCIR_AN1()
			/des='[TLT] Retourne la 1ère année hors archive de DCIR';
	%global dcir_an1;
%put DCIR TEST: &dcir_an1;
proc sql noprint;
	create table sasdata1._dcir_an1 as
		select Memname
			from dictionary.tables
				where Libname='ORAVUE' and Memname like 'ER\_PRS\_F\_%' escape '\';
	select put(input(max(scan(Memname,-1,'_')),4.)+1,z4.) into :DCIR_AN1
		from sasdata1._dcir_an1;
	drop table sasdata1._dcir_an1;
quit;

%mend DCIR_AN1;

%macro J9K(G,D)
			/des='[TLT] Jointure sur les 9 clés entre 2 tables de DCIR - DCT exclus';
		&G..DCT_ORD_NUM=&D..DCT_ORD_NUM AND
		&G..FLX_DIS_DTD=&D..FLX_DIS_DTD AND
		&G..FLX_EMT_ORD=&D..FLX_EMT_ORD AND
		&G..FLX_EMT_NUM=&D..FLX_EMT_NUM AND
		&G..FLX_EMT_TYP=&D..FLX_EMT_TYP AND
		&G..FLX_TRT_DTD=&D..FLX_TRT_DTD AND
		&G..ORG_CLE_NUM=&D..ORG_CLE_NUM AND 
		&G..PRS_ORD_NUM=&D..PRS_ORD_NUM	AND 
		&G..REM_TYP_AFF=&D..REM_TYP_AFF
%mend J9K;

%macro PRS_PHA(SOI_DTD_DDMMAAAA=,
				SOI_DTF_DDMMAAAA=,
				NB_MOIS_FLX=,
				TABLE=,
				REINIT=,
				CODE_ATC=)
			/des='[MB/TLT] Extraction DCIR depuis les tables ER_PRS_F et ER_PHA_F par itération sur les dates FLX_DIS_DTD';
	/** Macro Basée sur la méthode CQSLFMens de M. TLT **/
	%dcir_an1;

	%let soi_dtd= %sysfunc(inputn(&SOI_DTD_DDMMAAAA,DDMMYY8),date9);
	%let soi_dtf= %sysfunc(inputn(&SOI_DTF_DDMMAAAA,DDMMYY8),date9);

	%if &REINIT=YES %then
		%_eg_conditional_dropds(sasdata1.&table);

	/*** La boucle sur les nombres de mois de flux : Début***/
	%do nm=1 %to &NB_MOIS_FLX.;
		 
		%let FLX=%sysfunc(intnx(MONTH,"&soi_dtd"d,&nm),date9.);
		
		%put flx value: &flx;
		/** Est-ce que le FLX pointe sur une archive **/
		%if %sysevalf("&flx."d>"01JAN&dcir_an1."d) %then
			%let arc=;
		%else %if %substr(&flx,3,3)=JAN %then
			%let arc=_%eval(%substr(&flx,6,4)-1);
		%else %let arc=_%substr(&flx,6,4);
		%put ### Itération %sysfunc(sum(1,&nm),z2.) FLX=&FLX SOI_DTD=&soi_dtd SOI_DTF=&soi_dtf %sysfunc(datetime(),datetime.);
		%put annee archive : &arc;
		/** Est-ce que la table résultat existe? Si oui insérer, sinon créer **/
		proc sql;

			%if %sysfunc(exist(sasdata1.&table.))=0 %then
				%do;
					create table sasdata1.&table as
				%end;
			%else
				%do;
					insert into sasdata1.&table
				%end;

			select distinct prs.ben_nir_psa,
				prs.ben_rng_gem,
				prs.exe_soi_dtd,
				atc.PHA_ATC_CLA

			from 
				oravue.er_prs_f&arc prs inner join oravue.er_pha_f&arc pha on %j9k(prs,pha),
				oravue.ir_pha_r atc

			where

				prs.exe_soi_dtd between "&soi_dtd:0:0:0"dt and "&soi_dtf:0:0:0"dt
				and atc.PHA_PRS_IDE = pha.PHA_PRS_IDE
				and substr(atc.PHA_ATC_CLA,1,7) in &CODE_ATC
				and prs.FLX_DIS_DTD="&FLX:0:0:0"dt;
	%end;

	/*** Fin de la boucle ***/
%mend PRS_PHA;


%let dtd = 01012006;
%let dtf = 31122008;


%let out_file_name = ms_atc_06_08;

/*** Exécution de la macro ***/

/*

attention, il convient de modifier la taille du caractere dans substr si la longueur du code 
ATC est amenee a changer

*/

%PRS_PHA(SOI_DTD_DDMMAAAA=&dtd,
			SOI_DTF_DDMMAAAA=&dtf,
			NB_MOIS_FLX=48,
			TABLE=&out_file_name,
			REINIT=YES,
			CODE_ATC=('L03AB07','L03AB08','L03AB13','L03AX13',
					  'L04AA23', 'L04AA27', 'L04AA31', 'L04AA36',
						'L04AA40', 'L04AA50', 'L04AA52', 'L04AX07',
						'L04AX09', 'N07XX07', 'N07XX09'));



/*

MEDICAMENTS INSCRITS DANS LA LISTE EN SUS 


*/





			/*******     PMSI IDENTIFICATION 


			************/

/************************************************************************************/

/*************************************************************************************************************/
/************   Sélectionner des hospitalisations MCO en fonction des DP ou DR ou DAS                  *******/
/************   Générer un fichier de séjours hospitaliers (1 ligne par séjour)                        *******/
/************   incluant des variables relatives au patient, au séjour et à l'établissement de santé   *******/
/*************************************************************************************************************/

/*************************************************************************************************************/

/* choix des codes de diagnostic - dans ce programme, les codes retenus sont les mêmes quel que soit le type de diagnostic DP, DR ou DAS */
/* liste des codes à MODIFIER */



/******* création de la liste des identifiants des séjours(eta_num/rsa_num) correspondant aux codes DP/DR/DAS souhaités *******/
%macro select_etanum_rsanum (aaaa=);
/*
%let code_ucd = ('3400894351368', '3400890012997', '3400892933405');
*/
%let code_ucd = ('9435136', '9293340', '9001299');

select distinct eta_num, rsa_num
from oravue.t_mco&aa.med
/* where UCD_UCD_COD in &code_ucd */
where UCD_COD in &code_ucd
      
%mend select_etanum_rsanum;

/******* Génération d'un fichier comprenant pour les séjours sélectionnés par la macro select_etanum_rsanum *******/
/******* des variables issues des tables T_MCOaaB, T_MCOaaC, T_MCOaaA, T_MCOaaD, T_MCOaaUM et T_MCOaaE      *******/
/******* le fichier en sortie comprend une ligne par séjour                                                 *******/

%macro select_mco (aaaa=, table=);
%let aa = %substr(&aaaa.,3,2);

/**** tables T_MCOaaB (description du séjour hospitalier) + T_MCOaaC (table de chaînage) ****/

	%if %sysfunc(exist(sasdata1.&table.))=0 %then
				%do;
					create table sasdata1.&table as
				%end;
			%else
				%do;
					insert into sasdata1.&table
				%end;	

    select t1.eta_num, t1.rsa_num, 
		/*	%if &aaaa. >= 2009 %then dhms(input(t1.ADM_MOIS || '/' || '01' || '/' || t1.DAT_ADM_ANN, mmddyy10.),0,0,0) format = datetime20. as exe_soi_dtd,
		   %if &aaaa. < 2009 %then dhms(input(t1.ADM_MOIS || '/' || '01' || '/' || t1.ANN, mmddyy10.),0,0,0) format = datetime20. as exe_soi_dtd,; */
           dhms(input(t1.ADM_MOIS || '/' || '01' || '/' || t1.DAT_ADM_ANN, mmddyy10.),0,0,0) format = datetime20. as exe_soi_dtd,
           t1.UCD_UCD_COD,
		   t2.nir_ano_17 as ben_nir_psa


    from oravue.t_mco&aa.med as t1,
         oravue.t_mco&aa.c as t2,
         (%select_etanum_rsanum(aaaa=&aaaa.)) as t3

    where (t1.eta_num = t3.eta_num and t1.rsa_num = t3.rsa_num) and
          (t2.eta_num = t3.eta_num and t2.rsa_num = t3.rsa_num);

%mend select_mco;


/******* Generation d'un fichier qui concatene les sejours de chaque annee                                  *******/
/******* Boucle sur les annees d'interet et appel de la macro select_mco pour l'annee				        *******/
/******* le fichier en sortie comprend une ligne par séjour                                                 *******/

%macro iterate_select_mco(ANNEE_DEB = , NB_ANNEES =, TABLE_NAME = );
proc sql;

%do i=0 %to &NB_ANNEES-1;
	
	%let n = %sysevalf(&ANNEE_DEB+&i);
	%put *** anne en cours : &n;

	proc sql;

		%select_mco(aaaa=&n, table=&TABLE_NAME)

	quit;

%end

quit;
%mend iterate_select_mco;

%let out_file_name_pmsi = ms_atc_sus_09_14;

%let yea_sta = 2009;
%let yea_ite = 6;

%iterate_select_mco(ANNEE_DEB = &yea_sta,
					NB_ANNEES = &yea_ite,
					TABLE_NAME = &out_file_name_pmsi);


%let code_ucd = ('9435136', '9293340', '9001299');
%let code_ucd = ('3400894351368', '3400890012997', '3400892933405');
proc sql;
create table work.sep as
select *
from oravue.t_mco17medatu
where UCD_UCD_COD in &code_ucd;
quit;

proc sql;
create table sasdata1.ms_atc_06_23 as
select ben_nir_psa, exe_soi_dtd 
from sasdata1.ms_atc_06_08
union
select ben_nir_psa, exe_soi_dtd
from sasdata1.ms_atc_09_23
union
select ben_nir_psa, exe_soi_dtd
from sasdata1.ms_atc_sus_10_22
;
quit;

