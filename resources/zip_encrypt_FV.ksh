#!/usr/bin/ksh
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! TYPE        : /usr/bin/ksh
# @(#)! NOM         : zip_encrypt_FV.ksh
# @(#)! RESUME      : cryptage et compression des donnees
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! AUTEUR      : PSI/SPI/ITA/IAP/IPR
# @(#)! DATE        : 12/02/2016
# @(#)! VERSION     : 1.0 - IPO
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! ENTREES     : $FV_SAS_IN / fichier XML du type EMETTEUR_ASSUREUR_DEP_HORODATAGE.xml
# @(#)! ENTREES     : $FV_SAS_IN / fichier XML du type E<n°_Siret_Emetteur>_A<n°_Siren_Assureur>_DEP_$(date +%Y.%m.%d_%H.%M.%S).xml
# @(#)! SORTIES     : $FV_SAS_IN fichier XML crypte et zip avec horodatage
# @(#)! ARCHIVE     : $FV_DATA/save
# @(#)! LOG         : $FV_LOG/$(date +%Y.%m.%d_%H.%M.%S)_zip_encrypt_FV.log
# @(#)! LOG         : $LogFile
# @(#)!----------------------------------------------------------------------------------------------
# @(#)! USAGE       : zip_encrypt_FV.ksh
# @(#)! PARAMETRES  : N/A
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
Datefic=$(date +%Y%m%d%H%M%S)
script=$(basename $0 .ksh)
LogFile=${FS_LOGS}/${ENV}/${APP}/${DateSys}_${script}.log
FIC_FV_COUNT=$(find $FV_SAS_IN | grep -i horodatage.xml$ | wc -l)
FIC_FV_XML=$(find ${FV_SAS_IN} | grep -i horodatage.xml$)
FIC_FV_XML_OK=$(echo ${FIC_FV_XML} | eval sed 's#HORODATAGE#${Datefic}#g')
FIC_FV_ZIP=$(basename ${FIC_FV_XML_OK} .xml).zip
FIC_FV_GPG=$(basename ${FIC_FV_ZIP} .zip).fvie
FIC_FV_ID_GPG=${FV_PARAM}/DGFiP_trf_id.lst


#---------------------------
# FONCTIONS
#---------------------------

#---------------------------
# DEBUT
#---------------------------

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

if [ ${FIC_FV_COUNT} -eq 1 ]
	then
	
		echo "[ INFO ] - Verif si fichier recu a une taille non nulle"
		if [ -s ${FIC_FV_XML} ]
        		then
                		echo "[ INFO ] - ${FIC_FV_XML} taille non nulle OK... Continue..."
        		else
                		echo "[ INFO ] - EXIT 0 - Le fichier ${FIC_FV_XML} est vide"
                		rm -f ${FIC_FV_XML} && Func_CR 0 && exit 0

		fi
		# SUPPRESSION ^Z eventuel :
		perl -pi -e 's/'$(echo "\032")'//g' ${FIC_FV_XML} && echo "[ INFO ] - Cleanning ^Z : OK" || echo "[ ERROR ] - Cleanning ^Z : KO"
		#echo "mv ${FIC_FV_XML} ${FIC_FV_XML_OK}" && {
		mv ${FIC_FV_XML} ${FIC_FV_XML_OK} && {
		echo "[ INFO ] - Le fichier recu est    : ${FIC_FV_XML}"
		echo "[ INFO ] - Le fichier traite sera : ${FIC_FV_XML_OK}" && echo ""
		echo ${Datefic} >> ${FIC_FV_ID_GPG} && echo "[ INFO ] - Id / Date du transfert : ${Datefic}"
				} || {
		echo "[ ERROR ] - EXIT 8 - Renommage avec date : KO" && Func_CR 8
				}
	else
		echo ${FIC_FV_COUNT}
		echo ${FIC_FV_XML}
		echo "[ ERROR ] - 0 ou plusieurs fichiers xml trouve. Verifiez dans le repertoire : ${FV_SAS_IN}"
		echo "[ ERROR ] - EXIT 8"
		Func_CR 8
fi

############ Debut
######### RBO 24/02/2023
Code_FV_Emetteur=`cat $FIC_FV_XML_OK|grep idEmet|awk -F "idEmet" '{print $2}'|awk -F "\"" '{print $2}'`
Code_FV_Assureur=`cat $FIC_FV_XML_OK|grep idEmet|grep idDep|awk -F "idDep" '{print $2}'|awk -F "\"" '{print $2}'|awk -F "\-" '{print $1}'`
ct_E=`echo $Code_FV_Emetteur|tr -d '\\n'|wc -c`
ct_A=`echo $Code_FV_Assureur|tr -d '\\n'|wc -c`

echo "[ INFO ] -Code_FV_Emetteur:  " $Code_FV_Emetteur + $ct_E
echo "[ INFO ] -Code_FV_Assureur:  " $Code_FV_Assureur + $ct_A

if [ ${ct_E} != 14 ]
        then
	 echo "[ ERROR ] - SIRET invalide. Verifiez dans le repertoire : ${FV_SAS_IN}"
         echo "[ ERROR ] - EXIT 8"
         Func_CR 8
        fi
if [ ${ct_A} != 9 ]
        then
         echo "[ ERROR ] - SIREN invalide. Verifiez dans le repertoire : ${FV_SAS_IN}"
         echo "[ ERROR ] - EXIT 8"
         Func_CR 8
        fi

FIC_FV_XML_OK_tmp=${FV_SAS_IN}"/E"${Code_FV_Emetteur}"_A"${Code_FV_Assureur}"_DEP_"${Datefic}".xml"
mv ${FIC_FV_XML_OK} ${FIC_FV_XML_OK_tmp}
FIC_FV_XML_OK=${FIC_FV_XML_OK_tmp}
FIC_FV_ZIP=$(basename ${FIC_FV_XML_OK} .xml).zip
FIC_FV_GPG=$(basename ${FIC_FV_ZIP} .zip).fvie
echo "[ INFO ] -FIC_FV_XML_OK:   " $FIC_FV_XML_OK
echo "[ INFO ] -FIC_FV_ZIP:   " $FIC_FV_ZIP
echo "[ INFO ] -FIC_FV_GPG:   " $FIC_FV_GPG
######### RBO 24/02/2023
############## Fin
echo "[ INFO ] - Zippage :"
cd ${FV_SAS_IN}
zip -9 ${FIC_FV_ZIP} $(basename ${FIC_FV_XML_OK})
if [ $? -eq 0 ]
	then
		rm -f ${FIC_FV_XML_OK} && echo "[ INFO ] - Fichier zippe avec succes : OK"
		echo "[ INFO ] - $(ls -l ${FIC_FV_ZIP})" && echo ""
	else
		echo "[ ERROR ] - EXIT 8 - Zippage : KO" && Func_CR 8

fi
echo "[ END  ] - Zippage :FIN"
# Creation du fichier ~/.gnupg/gpg.conf :

echo "[ INFO ] - Creation du fichier gpg.conf"

echo "default-recipient-self
default-recipient bureau.si1d-ficovie@dgfip.finances.gouv.fr
require-cross-certification
keyserver hkp://keys.gnupg.net
no-greeting
no-secmem-warning
no-emit-version
no-comments
openpgp
keyid-format long
default-key ${GPG_KEY}
local-user ${GPG_KEY}
encrypt-to ${GPG_KEY}
personal-digest-preferences SHA256 SHA384 SHA512 SHA224 RIPEMD160
personal-cipher-preferences CAMELLIA256 AES256 TWOFISH CAMELLIA192 AES192 CAMELLIA128 AES BLOWFISH
bzip2-compress-level 9
compress-level 9
personal-compress-preferences BZIP2 ZIP ZLIB" > ~/.gnupg/gpg.conf

Test_File ~/.gnupg/gpg.conf

echo ""
echo "[ INFO ] - Cryptage GnuPG :"

gpg -o ${FIC_FV_GPG} -v -z 6 -e ${FIC_FV_ZIP} 
if [ $? -eq 0 ]
        then
                echo "" && echo "[ INFO ] - Fichier crypte avec succes : OK"
                rm -f ~/.gnupg/gpg.conf && echo "[ INFO ] - $(ls -l ${FIC_FV_GPG})"
		echo ""
		echo "[ INFO ] - FIN NORMALE"
        else
                echo "[ ERROR ] - EXIT 8 - Cryptage echoue : KO" && Func_CR 8

fi

Entete_fin

#---------------------------
# OBLIGATOIRE FIN :
#---------------------------

) > $LogFile 2>&1
cat $LogFile
Check_out

