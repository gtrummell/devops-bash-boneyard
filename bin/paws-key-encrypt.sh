#!/bin/bash

PDF_PASS=${1}
PDF_FILE=${2}

PDFB_HOME="/usr/local/Cellar/pdfbox/lib/"
PDFB_LIB=`find ${PDFB_HOME} -type f -name "pdfbox-app-*.jar"|tail -1`

if [[ -z ${JAVA_HOME} ]]; then
	echo "ERROR: JAVA_HOME is not set!"
	exit 1
fi

env java -jar ${PDFB_LIB} Encrypt \
-O ${PDF_PASS} \
-U ${PDF_PASS} \
-canAssemble false \
-canExtractContent false \
-canExtractForAccessibility false \
-canFillInForm false \
-canModify false \
-canModifyAnnotations false \
-canPrint false \
-canPrintDegraded false \
${PDF_FILE}