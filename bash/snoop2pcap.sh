## Name:	snoop2pcap
## Author:	keramida
## Modifier:	FOXX (frozenfoxx@github.com)
## Date:	12/04/2007
## Description:	this script will convert a Solaris snoop packet capture into a format that libpcap will
##		understand.

for fname in *.snoop ; do \
        newname="${fname%%.snoop}.pcap" ; \
        tshark -r "${fname}" -w "${newname}" && \
            rm -f "${fname}" ; \
        echo "rc=$? ${fname} -> ${newname}" ; \
end
