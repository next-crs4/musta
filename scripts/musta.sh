#!/bin/bash
PARAMS=""

WORKDIR=""
RESOURCESDIR=""
SAMPLESFILE=""
REFERENCE=""
BEDFILE=""
GERMLINEFILE=""
VARIANTFILE=""
help_flag=0

CMD="docker run "

# PARSE ARGS
while [ "$1" != "" ]; do

case $1 in
  -h | --help)
    PARAMS="${PARAMS} $1"
    help_flag=1
    shift
  ;;
  -w | --workdir)
    shift
    WORKDIR=$1
    shift
  ;;
  -rd | --resources-dir)
    shift
    RESOURCESDIR=$1
    shift
  ;;
  -r | --reference-file)
    shift
    REFERENCE=$1
    REFDIR=$(dirname "$REFERENCE")
    REFNAME=$(basename "$REFERENCE" | sed 's/\(.*\)\..*/\1/')
    shift
  ;;
   -b | --bed-file)
    shift
    BEDFILE=$1
    shift
  ;;
  -v | --variant-file)
    shift
    VARIANTFILE=$1
    shift
  ;;
  -g | --germline-resource)
    shift
    GERMLINEFILE=$1
    shift
  ;;
  -s | --samples-file)
    shift
    SAMPLESFILE=$1
    shift
  ;;
  *)
    PARAMS="${PARAMS} $1"
    shift

esac
done

# CHECK ARGS
[  -z "$WORKDIR" ] && [ $help_flag -eq 0 ] && [ -z "$RESOURCESDIR" ] \
&& echo "ERROR: -w | --workdir is a mandatory argument" && exit 1

[  ! -d "$WORKDIR" ] && [ $help_flag -eq 0 ] && [ -z "$RESOURCESDIR" ] \
&& echo "WARNING: ${WORKDIR} does not exist or is not a directory. Trying to create it." && mkdir -p $WORKDIR

[  ! -z "$RESOURCESDIR" ] && [  ! -d "$RESOURCESDIR" ] \
&& echo "WARNING: ${RESOURCESDIR} does not exist or is not a directory. Trying to create it." && mkdir -p $RESOURCESDIR

[  ! -z "$SAMPLESFILE" ] && [  ! -f "$SAMPLESFILE" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR: ${SAMPLESFILE} does not exist or is not a file.  Exiting..." && exit 1

[  ! -z "$REFERENCE" ] && [  ! -f "$REFERENCE" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR: ${REFERENCE} does not exist or is not a file.  Exiting..." && exit 1

[  ! -z "$REFERENCE" ] && [  -f "$REFERENCE" ] && [ ! -f "${REFERENCE}.fai" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR:  Fasta index file (.fai) for reference ${REFERENCE} does not exist." \
&& echo "Please see https://github.com/broadinstitute/gatk-docs/blob/master/gatk3-faqs/How_can_I_prepare_a_FASTA_file_to_use_as_reference%3F.md for help creating it." \
&& echo "Exiting..." \
&& exit 1

[  ! -z "$REFERENCE" ] && [  -f "$REFERENCE" ] && [ ! -f "${REFDIR}/${REFNAME}.dict" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR:  Fasta dict file (.dict) for reference ${REFERENCE} does not exist." \
&& echo "Please see https://github.com/broadinstitute/gatk-docs/blob/master/gatk3-faqs/How_can_I_prepare_a_FASTA_file_to_use_as_reference%3F.md for help creating it." \
&& echo "Exiting..." \
&& exit 1

[  ! -z "$BEDFILE" ] && [  ! -f "$BEDFILE" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR: ${BEDFILE} does not exist or is not a file.  Exiting..." && exit 1

[  ! -z "$GERMLINEFILE" ] && [  ! -f "$GERMLINEFILE" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR: ${GERMLINEFILE} does not exist or is not a file.  Exiting..." && exit 1

[  ! -z "$GERMLINEFILE" ] && [  -f "$GERMLINEFILE" ] && [ ! -f "${GERMLINEFILE}.idx" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR:  An index file (.idx) is required but was not found for file ${GERMLINEFILE}" \
&& echo " Try running gatk IndexFeatureFile on the input. See: https://gatk.broadinstitute.org/hc/en-us/articles/5358901172891-IndexFeatureFile" \
&& echo "Exiting..." && exit 1

[  ! -z "$VARIANTFILE" ] && [  ! -f "$VARIANTFILE" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR: ${VARIANTFILE} does not exist or is not a file.  Exiting..." && exit 1

[  ! -z "$VARIANTFILE" ] && [  -f "$VARIANTFILE" ] && [ ! -f "${VARIANTFILE}.idx" ] \
&& [ $help_flag -eq 0 ] && echo "ERROR:  An index file (.idx) is required but was not found for file ${VARIANTFILE}" \
&& echo " Try running gatk IndexFeatureFile on the input. See: https://gatk.broadinstitute.org/hc/en-us/articles/5358901172891-IndexFeatureFile" \
&& echo "Exiting..." && exit 1

# check workdir
[ $help_flag -eq 0 ] && [ -z "$RESOURCESDIR" ] && CMD="${CMD} -v ${WORKDIR}:/volumes/workdir" && PARAMS="${PARAMS} -w /volumes/workdir"


# check resources dir
[ $help_flag -eq 0 ] && [ -d "$RESOURCESDIR" ] \
&& CMD="${CMD} -v ${RESOURCESDIR}:/volumes/resources" && PARAMS="${PARAMS} -rd /volumes/resources"

# check samples file
[ $help_flag -eq 0 ] && [ -f "$SAMPLESFILE" ] \
&& CMD="${CMD} --mount type=bind,source=${SAMPLESFILE},target=/volumes/inputs/$(basename $SAMPLESFILE)" \
&& PARAMS="${PARAMS} -s /volumes/inputs/$(basename $SAMPLESFILE)"

# check reference file
[ $help_flag -eq 0 ] && [ -f "$REFERENCE" ] \
&& CMD="${CMD} --mount type=bind,source=${REFERENCE},target=/volumes/resources/$(basename $REFERENCE)" \
&& CMD="${CMD} --mount type=bind,source=${REFERENCE}.fai,target=/volumes/resources/$(basename ${REFERENCE}.fai)" \
&& CMD="${CMD} --mount type=bind,source=${REFDIR}/${REFNAME}.dict,target=/volumes/resources/${REFNAME}.dict" \
&& PARAMS="${PARAMS} -r /volumes/resources/$(basename $REFERENCE)"

# check bed file
[ $help_flag -eq 0 ] && [ -f "$BEDFILE" ] \
&& CMD="${CMD} --mount type=bind,source=${BEDFILE},target=/volumes/resources/$(basename $BEDFILE)" \
&& PARAMS="${PARAMS} -b /volumes/resources/$(basename $BEDFILE)"

# check germline resource
[ $help_flag -eq 0 ] && [ -f "$GERMLINEFILE" ] \
&& CMD="${CMD} --mount type=bind,source=${GERMLINEFILE},target=/volumes/resources/$(basename $GERMLINEFILE)" \
&& CMD="${CMD} --mount type=bind,source=${GERMLINEFILE}.idx,target=/volumes/resources/$(basename $GERMLINEFILE).idx" \
&& PARAMS="${PARAMS} -g /volumes/resources/$(basename $GERMLINEFILE)"

# check variant file
[ $help_flag -eq 0 ] && [ -f "$VARIANTFILE" ] \
&& CMD="${CMD} --mount type=bind,source=${VARIANTFILE},target=/volumes/resources/$(basename $VARIANTFILE)" \
&& CMD="${CMD} --mount type=bind,source=${VARIANTFILE}.idx,target=/volumes/resources/$(basename $VARIANTFILE).idx" \
&& PARAMS="${PARAMS} -v /volumes/resources/$(basename $VARIANTFILE)"

if [ -f "$SAMPLESFILE" ]; then

  mounts=()
  for line in `cat ${SAMPLESFILE}`
  do
    if [ -f $line ]; then
        filename=$(basename $line)
        extension="${filename##*.}"
        if [ $extension == 'bam' ]; then
          [ ! -f "${line}.bai" ] && echo "ERROR: Some input vam files are not indexed." && \
          echo "Please index all input files: samtools index ${line}" && \
          echo "See: http://quinlanlab.org/tutorials/samtools/samtools.html#samtools-index" && \
          echo "Exiting..." && exit 1

          CMD="${CMD} --mount type=bind,source="${line}.bai",target=/volumes/inputs/${filename}.bai"

        fi
        CMD="${CMD} --mount type=bind,source="${line}",target=/volumes/inputs/${filename}"
#        mounts+=("${filename}")
#        echo ${mounts[*]}
#        # shellcheck disable=SC2076
#        if echo ${mounts[*]} | grep -q -w "${filename}"; then
#          tmp=""
#        else
#        fi
    fi
  done
fi

CMD="${CMD} musta:Dockerfile musta ${PARAMS}"

#echo $CMD

eval $CMD