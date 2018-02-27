#!/bin/bash

help () {
	cat <<-EOF
pdfbox-encrypt <file> <password>

Encrypts a PDF file with preconfigured security settings.
<file>       Name of PDF file to encrypt (required)
<password>   Password to encrypt PDF file (required)
EOF
}

for VAR in ${1} ${2}; do
	if [[ -z ${VAR} ]]; then
		help
		exit 1
	fi
done

pdfbox_home="/usr/local/Cellar/pdfbox"
pdfbox_ver="1.8.8"
pdfbox_jar="${pdfbox_home}/lib/pdfbox-app-${pdfbox_ver}.jar"

java -jar ${pdfbox_jar} Encrypt -O BandPageNoWrite2015 -U ${2} -canAssemble false -canExtractContent false -canExtractForAccessibility false -canFillInForm false -canModify false -canModifyAnnotations false -canPrint false -canPrintDegraded false ${1}
