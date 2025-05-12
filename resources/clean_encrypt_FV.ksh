#!/usr/bin/ksh
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! TYPE        : /usr/bin/ksh
# @(#)! NOM         : clean_encrypt_FV.ksh
# @(#)! RESUME      : Archivage (mv) et purges rotative du fichier zippe avant envoi a la DGFIP
# @(#)!             : Purge parametrable sur la retention en nombre de jour
# @(#)!             : Si aucun parametre passe au script, alors 90 jours de retention par defaut
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! AUTEUR      : PSI/SPI/ITA/IAP/IPR
# @(#)! DATE        : 12/02/2016
# @(#)! VERSION     : 1.0 - IPO
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! ENTREES     : $FV_SAS_IN/fichier FICOVIE (zippe uniquement) fichier.zip
# @(#)! ENTREES     : $FV_SAS_OUT/ok/FICOV_BIL_CONCAT_date.xml >>> Fichier retour BILAN
# @(#)! SORTIES     : $FV_SAS_IN/E<nÂ°_Siret_Emetteur>_A<nÂ°_Siren_Assureur>_DEP_20160317132836.zip #exemple
# @(#)! ARCHIVE     : $FV_DATA/save/E<nÂ°_Siret_Emetteur>_A<nÂ°_Siren_Assureur>_DEP_20160317132836.fvie #exemple
# @(#)! LOG         : $FV_LOG/$(date +%Y.%m.%d_%H.%M.%S)_${script}.log
# @(#)! LOG         : $LogFile
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! USAGE       : clean_encrypt_FV.ksh
# @(#)! PARAMETRES  : [ AUNCUN ] = Retention de 90j (default)
# @(#)! PARAMETRES  : [ Nombre n ] = Nombre de jour de retention (n=chiffre)
# @(#)! UTILISATEUR : u${ENV}${APP}[a|$COMPAGNY]1
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! CODE RETOUR :  0 - Succes
# @(#)!                4 - Avertissement (erreur non bloquante)
# @(#)!                8 - Fatale (erreur bloquante)
# @(#)!----------------------------------------------------------------------------------------------

#############################
# Passage en mode Debug
#############################

# set -vx

#############################
# APPEL FunctionsForScripts
#############################

. FunctionsForScripts && echo "[ INFO ] FunctionsForScripts : OK" || $(echo "[ ERROR ] - EXIT 8 - Fichier FunctionsForScripts : KO" && exit 8)

#############################
# INIT VARIABLES :
#############################

DateSys=$(date +%Y.%m.%d_%H.%M.%S)
script=$(basename $0 .ksh)
LogFile=${FS_LOGS}/${ENV}/${APP}/${DateSys}_${script}.log
FIC_FV_ZIP_COUNT=$(find ${FV_SAS_IN} | grep .zip$ | grep -vi BIL | wc -l)
FIC_FV_ZIP=$(find ${FV_SAS_IN} | grep .zip$ | grep -vi BIL)
[ "$1" ] && RETENTION=${1} || RETENTION=90

#---------------------------
# FONCTIONS
#---------------------------

#---------------------------
# DEBUT
#---------------------------

# Verif user ficove :
if [ $APP != fv ]
        then
                echo "[ ERROR ] - EXIT 8 - Le user : $USER nest pas autorise pour executer ce traitement" && exit 8
fi


#---------------------------
#OBLIGATOIRE DEBUT :
#---------------------------

(

Cartouche && Entete_debut
Clean_log && echo "[ INFO ] - Purge log a 90 j : OK" || echo "[ ERROR ] Purge log a 90 j : KO"

#---------------------------

echo "[ INFO ] - Debut des traitements"

if [ ${FIC_FV_ZIP_COUNT} -eq 0 ]
        then
		echo "[ WARN ] - 0 ou plusieurs fichiers zip trouve. Verifiez dans le repertoire : ${FV_SAS_OUT}"
		echo "[ INFO ] - Aucun archivage requis...Continue to next steps..."
        else
		for i in $(find ${FV_SAS_IN} | grep zip$ | grep -vi BIL)

			do
				Test_File ${i}
                		mv ${i} ${FV_DATA}/save/ && echo "[ INFO ] - Archivage du fichier zippe dans ${FV_DATA}/save/$(basename ${i}) : OK" || $(echo "[ ERROR ] - EXIT 8 - Archivage du fichier zippe : KO" && Func_CR 8)
			done

                echo ""
fi


echo "[ INFO ] - Lancement de la purge dans ${FV_DATA}/save"
echo "[ INFO ] - Purge rotative sur une retention de ${RETENTION} jours"
echo "[ INFO ] - Les fichier suivant ont été supprimes :"
find ${FV_DATA}/save/ -mtime ${RETENTION} | grep .zip$ 
find ${FV_DATA}/save/ -mtime ${RETENTION} | grep .zip$ | perl -nle unlink
if [ $? -eq 0 ]
        then
                echo "[ INFO ] - Purge rotative ${FV_DATA}/save : OK"
		echo ""
        else
		echo "[ ERROR ] - Purge rotative  : KO"
		echo "[ ERROR ] - Verifiez les droits"
                Func_CR 8
fi

echo ""
echo "[ INFO ] - Lancement de la purge dans $FV_SAS_OUT/ok"
echo "[ INFO ] - Purge rotative sur une retention de ${RETENTION} jours"
echo "[ INFO ] - Les fichier suivant ont été supprimes :"
find $FV_SAS_OUT/ok/ -mtime ${RETENTION} | grep FICOV_BIL_CONCAT | grep xml$
find $FV_SAS_OUT/ok/ -mtime ${RETENTION} | grep FICOV_BIL_CONCAT | grep xml$ | perl -nle unlink
if [ $? -eq 0 ]
        then
                echo "[ INFO ] - Purge rotative $FV_SAS_OUT/ok : OK"
                echo ""
                echo "[ INFO ] - FIN NORMALE"
        else
                echo "[ ERROR ] - Purge rotative  : KO"
                echo "[ ERROR ] - Verifiez les droits"
                Func_CR 8
fi

#---------------------------

Entete_fin

#---------------------------
# OBLIGATOIRE FIN :
#---------------------------

) > $LogFile 2>&1
cat $LogFile
Check_out

