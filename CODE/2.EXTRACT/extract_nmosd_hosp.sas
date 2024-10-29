/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Program name : extract_nmosd_hosp
/* Objective : 
extract hospital discharges with a diagnosis code for NMOSD.

-> the 06-08 and 09-23 periods are trackled separaterly since the table names changed
/* Tables : output table: nmosd_pmsi_06_23 in the sasdata1 library

/*****************************************************************************/




/************************************************************************************/
/*   Copyright © 2020-2021 Santé publique France                                    */
/************************************************************************************/

/*************************************************************************************************************/
/************   Sélectionner des hospitalisations MCO en fonction des DP ou DR ou DAS                  *******/
/************   Générer un fichier de séjours hospitaliers (1 ligne par séjour)                        *******/
/************   incluant des variables relatives au patient, au séjour et à l'établissement de santé   *******/
/*************************************************************************************************************/

/*************************************************************************************************************/

/* choix des codes de diagnostic - dans ce programme, les codes retenus sont les mêmes quel que soit le type de diagnostic DP, DR ou DAS */
/* liste des codes à MODIFIER */
%macro dgn_cod (dgn=);
    &dgn. like 'G36%'
%mend;

/* choix du type de diagnostic à sélectionner :
   -> 1 = DP uniquement
   -> 2 = DP ou DR 
   -> 3 = DP ou DR ou DAS */
%let select_dpra = 3;

/* gestion d'affichage des variables DAS, actes et UM pour limiter la taille de la table de sortie */
/* par défaut le programme inclut dans le fichier en sortie : 20 actes et DAS, et 10 UM */
/* à modifier si nécessaire */
%let aff_das = ;
%let aff_act = ;
%let aff_um = ;

/********************************************************************************/

/* liste des finess géographiques APHP, APHM et HCL à supprimer pour éviter les doublons */
%let finess_out = '130780521' '130783236' '130783293' '130784234' '130804297'
                  '600100101' '750041543' '750100018' '750100042' '750100075'
                  '750100083' '750100091' '750100109' '750100125' '750100166'
                  '750100208' '750100216' '750100232' '750100273' '750100299'
                  '750801441' '750803447' '750803454' '910100015' '910100023'
                  '920100013' '920100021' '920100039' '920100047' '920100054'
                  '920100062' '930100011' '930100037' '930100045' '940100027'
                  '940100035' '940100043' '940100050' '940100068' '950100016'
                  '690783154' '690784137' '690784152' '690784178' '690787478'
                  '830100558';

/******* création de la liste des identifiants des séjours(eta_num/rsa_num) correspondant aux codes DP/DR/DAS souhaités *******/
%macro select_etanum_rsanum (aaaa=);
select distinct eta_num, rsa_num
from oravue.t_mco&aa.b
where %if &select_dpra. = 1 %then %do;
          %dgn_cod(dgn=dgn_pal)
      %end;
      %else %if &select_dpra. = 2 %then %do;
          %dgn_cod(dgn=dgn_pal) or %dgn_cod(dgn=dgn_rel)
      %end;
      %else %if &select_dpra. = 3 %then %do;
          %dgn_cod(dgn=dgn_pal) or %dgn_cod(dgn=dgn_rel)
          union
          select distinct eta_num, rsa_num
          from oravue.t_mco&aa.d
          where %dgn_cod(dgn=ass_dgn)
          %if &aaaa. >= 2008 %then %do;
            union
            select distinct eta_num, rsa_num
              from oravue.t_mco&aa.um
              where %dgn_cod(dgn=dgn_pal) or %dgn_cod(dgn=dgn_rel)
          %end;
      %end;
%mend select_etanum_rsanum;

/******* Génération d'un fichier comprenant pour les séjours sélectionnés par la macro select_etanum_rsanum *******/
/******* des variables issues des tables T_MCOaaB, T_MCOaaC, T_MCOaaA, T_MCOaaD, T_MCOaaUM et T_MCOaaE      *******/
/******* le fichier en sortie comprend une ligne par séjour                                                 *******/
%macro select_mco (aaaa=, table=, ANNEE_DEB = , ANNEE_FIN =);
%let aa = %substr(&aaaa.,3,2);
%if &aff_das. = %then %let aff_das = 20;
%if &aff_act. = %then %let aff_act = 20;
%if &aff_um. = %then %let aff_um = 10;

/**** tables T_MCOaaB (description du séjour hospitalier) + T_MCOaaC (table de chaînage) ****/
proc sql;
    create table tmp1_bc_&aaaa. as
    select 
        t1.eta_num, t1.rsa_num, t2.sej_num, t1.sej_nbj length=3,
        t1.nbr_dgn length=3, t1.nbr_rum length=3, t1.nbr_act length=3, 
        t1.ent_mod, t1.ent_prv, t1.sor_mod, t1.sor_des, t1.sor_ann, t1.sor_moi, 
        %if &aaaa. >= 2009 %then t2.exe_soi_dtd, t2.exe_soi_dtf, ;
        t1.dgn_pal as dp, t1.dgn_rel as dr, t1.grg_ghm, t1.bdi_dep, t1.bdi_cod, 
        t1.cod_sex, t1.age_ann length=3, t1.age_jou length=3, t2.nir_ano_17,
           /* liste des codes retours */ 
        t2.fho_ret, t2.nai_ret, t2.nir_ret, t2.pms_ret, t2.sej_ret, t2.sex_ret
        %if &aaaa. >= 2006 %then , t2.dat_ret ;
        %if &aaaa. >= 2013 %then , t2.coh_nai_ret, t2.coh_sex_ret ;
    from 
        oravue.t_mco&aa.b as t1,
        oravue.t_mco&aa.c as t2,
        (%select_etanum_rsanum(aaaa=&aaaa.)) as t3
    where 
        (t1.eta_num = t3.eta_num and t1.rsa_num = t3.rsa_num) and
        (t2.eta_num = t3.eta_num and t2.rsa_num = t3.rsa_num)         
    order by t1.eta_num, t1.rsa_num;
quit;

proc sql;
    create table tmp2_bc_&aaaa. as
    select
        *,
        %dgn_cod(dgn=dp) as dp_is_dem,
        %dgn_cod(dgn=dr) as dr_is_dem
    from tmp1_bc_&aaaa.
    ;
quit;
/**** table T_MCOaaUM (unités médicales): à partir de 2006 ****/
proc sql;
    create table tmp1_um_&aaaa. as
    select t1.eta_num, t1.rsa_num,
            t1.dgn_pal, t1.dgn_rel
    from oravue.t_mco&aa.um as t1,
            (%select_etanum_rsanum(aaaa=&aaaa.)) as t3
    where (t1.eta_num = t3.eta_num and t1.rsa_num = t3.rsa_num)
    order by t1.eta_num, t1.rsa_num;
quit;

proc sql;
    create table tmp5_n_dp_dr_dem_um&aaaa. as
    select 
        eta_num, rsa_num,
        sum(%dgn_cod(dgn=dgn_pal)) as n_dp_um_dem,
        sum(%dgn_cod(dgn=dgn_rel)) as n_dr_um_dem
    from tmp1_um_&aaaa.
    group by eta_num, rsa_num
    order by eta_num, rsa_num;
quit;

/* /!\ ATTENTION /!\ chaque variable qu'on souhaite récupérer de la table UM, doit être tranposée */
/* cas dp_um et dr_um */

proc transpose data= tmp1_um_&aaaa.
                out= tmp2_um_dp_&aaaa. (keep= eta_num rsa_num dp_um1-dp_um&aff_um.)
                prefix= dp_um;
    by eta_num rsa_num;
    var dgn_pal;
run;

proc transpose data= tmp1_um_&aaaa.
                out= tmp2_um_dr_&aaaa. (keep= eta_num rsa_num dr_um1-dr_um&aff_um.)
                prefix= dr_um;
    by eta_num rsa_num;
    var dgn_rel;
run;



data tmp3_um_&aaaa.;
    merge tmp2_um_dp_&aaaa. (in= tab)
            tmp2_um_dr_&aaaa.
            tmp5_n_dp_dr_dem_um&aaaa.;
    by eta_num rsa_num;
    if tab;
run;



/**** table T_MCOaaD (diagnostics associés) ****/
proc sql;
    create table tmp1_d_&aaaa. as
    select t1.eta_num, t1.rsa_num, t1.ass_dgn
    from 
        oravue.t_mco&aa.d as t1,
        (%select_etanum_rsanum(aaaa=&aaaa.)) as t3
    where (t1.eta_num = t3.eta_num and t1.rsa_num = t3.rsa_num)             
    order by t1.eta_num, t1.rsa_num;
quit;

/**** création d'une table regroupant l'ensemble des diagnostics associés issus des table T_MCOaaD et T_MCOaaUM ****/

data tmp2_d_&aaaa.;
    set tmp1_d_&aaaa.
        tmp1_um_&aaaa. (keep= eta_num rsa_num dgn_pal
                        rename= (dgn_pal = ass_dgn))
        tmp1_um_&aaaa. (keep= eta_num rsa_num dgn_rel
                        rename= (dgn_rel = ass_dgn)
                        where= (not missing(ass_dgn)));
run;

proc sort 
    data= tmp2_d_&aaaa. out= tmp3_d_&aaaa. nodupkey;
    by eta_num rsa_num ass_dgn;
run;

/* nettoyage des DAS ayant le même diagnostic en DP, manquants ou erronés */
data tmp2_dp_&aaaa.;
    set tmp2_bc_&aaaa. (keep= eta_num rsa_num dp);
run;

data tmp4_d_&aaaa. (drop=dp);
    merge tmp3_d_&aaaa. tmp2_dp_&aaaa.;
    by eta_num rsa_num;
    if ass_dgn = dp or missing(ass_dgn) or lowcase(ass_dgn) = 'xxxx' then delete;
run;

proc sql;
    create table tmp5_n_d_&aaaa. as
    select eta_num, rsa_num, count(ass_dgn) length=3 as n_das, sum(%dgn_cod(dgn=ass_dgn)) as n_das_is_dem
    from tmp4_d_&aaaa.
    group by eta_num, rsa_num
    order by eta_num, rsa_num;
quit;

proc transpose data= tmp4_d_&aaaa.
               out= tmp5_d_&aaaa. (keep= eta_num rsa_num das1-das&aff_das.)
               prefix= das;
    by eta_num rsa_num;
    var ass_dgn;
run;

data tmp6_d_&aaaa.;
    merge tmp5_n_d_&aaaa. (in= tab)
          tmp5_d_&aaaa.;
    by eta_num rsa_num;
    if tab;
run;


/**** table FINALE : rassembler les différentes tables ****/
/**** un enregistrement par séjour hospitalier ****/
data tmp3_&aaaa.;
    merge tmp2_bc_&aaaa. (in= tab)
          tmp6_d_&aaaa.
          tmp3_um_&aaaa.;
    by eta_num rsa_num;
    if tab;
    if missing(n_das) then n_das = 0;
run;



data fullmco_&aaaa. (drop= tmp:);
    set tmp3_&aaaa. (rename= (sej_num = tmp_sejnum
                            %if &aaaa. >= 2009 %then %do;
                                exe_soi_dtd = tmp_exesoidtd
                                exe_soi_dtf = tmp_exesoidtf
                            %end;));
    /* création de la variable cr_ok :1=ensemble des codes retours valides / 0=au moins 1 code retour erroné */
    length cr_ok $ 1;
    if nir_ret = '0' and nai_ret = '0' and sex_ret = '0' and
        sej_ret = '0' and fho_ret = '0' and pms_ret = '0' 
        %if &aaaa. >= 2006 %then and dat_ret = '0' ;
        %if &aaaa. >= 2013 %then and coh_nai_ret = '0' and coh_sex_ret = '0' ;
        then cr_ok = '1';
    else do;
        cr_ok = '0';
        nir_ano_17 = 'XXXXXXXXXXXXXXXXX';
        tmp_sejnum = 'XXXX';
    end;

    /* le numéro de séjour (SEJ_UM) est modifié pour les années 2006 à 2008 afin de permettre l’éventuel chaînage 
    des séjours d’un même patient sur une période incluant les années 2009 et suivantes */ 
    length sej_num 4;
    %if &aaaa. = 2005 %then %do;
        if tmp_sejnum = 'XXXX' then call missing(sej_num);
        else sej_num = input(tmp_sejnum, $4.);
    %end;
    %else %if 2006 <= &aaaa. and &aaaa. <= 2008 %then %do;
        if tmp_sejnum = 'XXXX' then call missing(sej_num);
        else sej_num = input(tmp_sejnum, $4.) + 18263;
    %end;
    %else %if &aaaa. >= 2009 %then %do;
        if tmp_sejnum = 'XXXXX' then call missing(sej_num);
        else sej_num = input(tmp_sejnum, $5.);
    %end;

    /* dates entières de soins : disponible à partir de 2009 */
    %if &aaaa. >= 2009 %then %do;
        length soin_dtd soin_dtf 6;
        soin_dtd = datepart(tmp_exesoidtd);
        soin_dtf = datepart(tmp_exesoidtf);
        format soin_dtd soin_dtf ddmmyy10.;
    %end;

    /* age = 0 */
    if missing(age_ann) and not missing(age_jou) then age_ann = 0;

    /* suppression des séjours en erreur (GHM commençant par 90) */
    if grg_ghm =: "90" then delete;
    
    /* suppression des Finess en doublon */
    if eta_num in (&finess_out.) then delete;


run;

data mco_&aaaa. (drop = coh_nai_ret coh_sex_ret nir_ret nai_ret);
    set fullmco_&aaaa.;
run;

/**** nettoyage des tables temporaires ****/
proc datasets lib=work nolist nodetails;
    delete tmp: ;
run;


%if %sysfunc(exist(sasdata1.&table.)) = 0 %then %do;
    proc sql;
        create table sasdata1.&table. as
        select *
        from mco_&aaaa.
        where year(soin_dtd) >= &ANNEE_DEB and year(soin_dtd) <= &ANNEE_FIN;
    quit;
%end;
%else %do;
    proc sql;
        create table temp_table as
        select *
        from mco_&aaaa.
        where year(soin_dtd) >= &ANNEE_DEB and year(soin_dtd) <= &ANNEE_FIN;
    quit;

	
    proc append base=sasdata1.&table. data=temp_table force;
    run;


    proc datasets library=work nolist;
        delete temp_table;
    run;
%end;


%mend select_mco;


%macro iterate_select_mco(ANNEE_DEB = , ANNEE_FIN =, TABLE_NAME = );
	%let NB_ANNEES = %sysevalf(&ANNEE_FIN - &ANNEE_DEB + 2);

    %do i=0 %to &NB_ANNEES - 1;
        %let n = %sysevalf(&ANNEE_DEB+&i);
        %put *** Annee en cours : &n;
        %select_mco(aaaa=&n, table=&TABLE_NAME, ANNEE_DEB =&ANNEE_DEB , ANNEE_FIN =&ANNEE_FIN );
    %end;

%mend iterate_select_mco;


%let out_file_name_mco = nmosd_pmsi_09_23;

%let yea_sta = 2009;
%let yea_end = 2023;

%iterate_select_mco(ANNEE_DEB = &yea_sta,
        ANNEE_FIN = &yea_end,
        TABLE_NAME = &out_file_name_mco);

proc sql;
create table sasdata1.&out_file_name_mco as
select *,
		nir_ano_17 as ben_nir_psa,
		dhms(soin_dtd,0,0,0) format = datetime20. as exe_soi_dtd
from sasdata1.&out_file_name_mco;
quit;



/*





					06 - 09 PERIOD



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
%macro dgn_cod (dgn=);
    &dgn. like 'G36%'
%mend;

/* choix du type de diagnostic à sélectionner :
   -> 1 = DP uniquement
   -> 2 = DP ou DR 
   -> 3 = DP ou DR ou DAS */
%let select_dpra = 3;


/******* création de la liste des identifiants des séjours(eta_num/rsa_num) correspondant aux codes DP/DR/DAS souhaités *******/
%macro select_etanum_rsanum (aaaa=);
select distinct eta_num, rsa_num
from oravue.t_mco&aa.b
where %if &select_dpra. = 1 %then %do;
          %dgn_cod(dgn=dgn_pal)
      %end;
      %else %if &select_dpra. = 2 %then %do;
          %dgn_cod(dgn=dgn_pal) or %dgn_cod(dgn=dgn_rel)
      %end;
      %else %if &select_dpra. = 3 %then %do;
          %dgn_cod(dgn=dgn_pal) or %dgn_cod(dgn=dgn_rel)
          union
          select distinct eta_num, rsa_num
          from oravue.t_mco&aa.d
          where %dgn_cod(dgn=ass_dgn)
          %if &aaaa. >= 2008 %then %do;
              union
              select distinct eta_num, rsa_num
              from oravue.t_mco&aa.um
              where %dgn_cod(dgn=dgn_pal) or %dgn_cod(dgn=dgn_rel)
          %end;
      %end;
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

    select t1.eta_num, t1.rsa_num, t2.sej_num, t1.sej_nbj length=3,
           t1.nbr_dgn, t1.sor_ann, t1.sor_moi, 
           %if &aaaa. >= 2009 %then t2.exe_soi_dtd,
		   %if &aaaa. < 2010 %then dhms(input(t2.SOR_MOI || '/' || '01' || '/' || t2.SOR_ANN, mmddyy10.),0,0,0) format = datetime20. as exe_soi_dtd,;
           t1.dgn_pal as dp,
			t1.dgn_rel as dr,
           t1.cod_sex, t1.age_ann length=3, t1.age_jou length=3, t2.nir_ano_17 as ben_nir_psa


    from oravue.t_mco&aa.b as t1,
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

%let out_file_name_pmsi = nmosd_pmsi_06_09;

%let yea_sta = 2006;
%let yea_ite = 3;

%iterate_select_mco(ANNEE_DEB = &yea_sta,
					NB_ANNEES = &yea_ite,
					TABLE_NAME = &out_file_name_pmsi);


proc sql;
create table sasdata1.&out_file_name_pmsi as
select *,
	dhms(input(SOR_MOI || '/' || '01' || '/' || SOR_ANN, mmddyy10.),0,0,0) format = datetime20. as exe_soi_dtd
from sasdata1.&out_file_name_pmsi ;
quit;



proc sql;
create table sasdata1.nmosd_pmsi_06_23 as
select ben_nir_psa, exe_soi_dtd
from sasdata1.nmosd_pmsi_06_09
union
select ben_nir_psa, exe_soi_dtd
from sasdata1.nmosd_pmsi_09_23
;
quit;


