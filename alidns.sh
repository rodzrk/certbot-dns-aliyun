#!/bin/bash

if ! command -v aliyun >/dev/null; then
	echo "错误: 你需要先安装 aliyun 命令行工具 https://help.aliyun.com/document_detail/121541.html。" 1>&2
	exit 1
fi

# 获取各级域名信息,用于适配阿里云api;当前仅支持2级泛域名证书或3级泛域名证书的申请
DOT_SIZE=$(echo $CERTBOT_DOMAIN|grep -o '\.'|wc -l)
echo $DOT_SIZE
if ((1 == $DOT_SIZE)); then
  DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
  SUB_DOMAIN=$(expr match "$CERTBOT_DOMAIN" '\(.*\)\..*\..*')
elif ((2 == $DOT_SIZE)); then
  DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\..*\)')
  SUB_DOMAIN=$(expr match "$CERTBOT_DOMAIN" '\(.*\)\..*\..*\..*')
else
  echo "不支持: " $CERTBOT_DOMAIN
  exit 1
fi

if [ -z $DOMAIN ]; then
    DOMAIN=$CERTBOT_DOMAIN
fi
if [ ! -z $SUB_DOMAIN ]; then
    SUB_DOMAIN=.$SUB_DOMAIN
fi

if [ $# -eq 0 ]; then
	aliyun alidns AddDomainRecord \
		--DomainName $DOMAIN \
		--RR "_acme-challenge"$SUB_DOMAIN \
		--Type "TXT" \
		--Value $CERTBOT_VALIDATION
	/bin/sleep 20
else
	RecordId=$(aliyun alidns DescribeDomainRecords \
		--DomainName $DOMAIN \
		--RRKeyWord "_acme-challenge"$SUB_DOMAIN \
		--Type "TXT" \
		--ValueKeyWord $CERTBOT_VALIDATION \
		| grep "RecordId" \
		| grep -Eo "[0-9]+")

	aliyun alidns DeleteDomainRecord \
		--RecordId $RecordId
fi
