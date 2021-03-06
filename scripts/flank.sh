#!/usr/bin/env bash

BUCKET_NAME=coverage_stuff #Put bucket name here
DIR_NAME=$(($(date +%s)))

sed -i.bak '/gcloud-bucket/d' config.properties
echo "gcloud-bucket: ${BUCKET_NAME}/${DIR_NAME}" >> config.properties
rm config.properties.bak

rm -rf misc/coverage_reports/*.exec

gsutil cp config.properties  gs://${BUCKET_NAME}/${DIR_NAME}/

java -jar misc/Flank-2.0.1.jar -a app/build/outputs/apk/debug/app-debug.apk -t app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk

REPORT_COUNT=$(gsutil ls gs://${BUCKET_NAME}/${DIR_NAME}/ | wc -l)
for number in `seq 0 ${REPORT_COUNT}`
do
    gsutil -q stat gs://${BUCKET_NAME}/${DIR_NAME}/${number}/*

    return_value=$?

    if [ ${return_value} == 0 ]; then
        test_report_directory_path_all_devices=$(gsutil ls gs://${BUCKET_NAME}/${DIR_NAME}/${number}/* | grep -e "/$")
        test_report_directory_path_single_device=(${test_report_directory_path_all_devices})
        download_path_for_coverage_report=${test_report_directory_path_single_device[0]}coverage.ec
        echo "Downloading coverage reports from: ${download_path_for_coverage_report}"
        gsutil cp ${download_path_for_coverage_report} ./misc/coverage_reports/${number}.exec
    fi

done