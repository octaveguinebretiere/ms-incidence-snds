/*****************************************************************************/
/*              TIME TRENDS INCIDENCE OF MULTIPLE SCLEROSIS                   */
/*****************************************************************************/

/*****************************************************************************/

/* Program name : extract_ltd
/* Objective : 
extract long term disease benefits with a diagnosis code for MS.

/* Tables : output table: ms_ald_09_23 in the sasdata1 library

/*****************************************************************************/


/***********   ALD INDENTIFICATION 

					***********/

/**************************************************************************************************/
/*********************************ALS *******************************************************/
/* GUINEBRETIERE (ICM)															*/
/* Base de code de l'HAS (Pierre-Alain Jachiet)									*/
/**************************************************************************************************/

/* on utilise les codes CIM 10 et non le numero d'ALD
qui n'est pas tjs bien renseigne et pas forcement stable dans le temps:
une table de correspondance IR_CIM_V existe pour 
identifier la correspondance ALD et Code CIM10 */

/* IR_IMB_R est une table france entiere non indexe sur le mois
de disposition du flux (contrairement a la table des prestations)*/

/** rcupereation de tous les bnf avec une ALD  enregistree avant 2022 dans le IR_IMB_R;*/
%macro ald_ind(TABLE_NAME = , CODE_ICD=);
/*
CODE POUR DETECTER LES NOUVELLES ALD
*/
proc sql;
	create table sasdata1.&TABLE_NAME as 
		select BEN_NIR_PSA,
			BEN_RNG_GEM,
			IMB_ALD_NUM,
			IMB_ALD_DTD as EXE_SOI_DTD,
			MED_MTF_COD

		from oravue.IR_IMB_R 
		where substr(MED_MTF_COD,1,3) in &CODE_ICD	
				;
quit;
%mend ald_ind;

%let out_file_name_ald = ms_ald_09_23;

%ald_ind(TABLE_NAME = &out_file_name_ald,
		CODE_ICD = ('G35'));


