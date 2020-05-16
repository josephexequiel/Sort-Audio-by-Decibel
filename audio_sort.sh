#!/bin/bash

function measure_db()
{
	FILENAME="$1"
	OUTPUT=`echo $(ffmpeg -i "$FILENAME" -af astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level -f null - 2>&1 | grep "RMS peak dB" | awk -F ':' '{print $2}') | awk '{print $1}'`;
	echo $OUTPUT;
	unset FILENAME OUTPUT;
}

function prepare_directory()
{
	WORK_OUTPUT="$1"
	if [[ -d "$WORK_OUTPUT/Output" ]];
	then
		echo "Cleaning up output directory."
		rm -rf "$WORK_OUTPUT/Output"
		mkdir -p "$WORK_OUTPUT/Output"
	else
		echo "Creating output directory.";
		mkdir -p "$WORK_OUTPUT/Output"
	fi;
	unset WORK_OUTPUT;
}

function prepare_revertdirectory()
{
	WORK_OUTPUT="$1"
	if [[ -d "$WORK_OUTPUT/Revert" ]];
	then
		echo "Cleaning up Revert directory."
		rm -rf "$WORK_OUTPUT/Revert"
		mkdir -p "$WORK_OUTPUT/Revert"
	else
		echo "Creating Revert directory.";
		mkdir -p "$WORK_OUTPUT/Revert"
	fi;
	unset WORK_OUTPUT;
}

function parse_directory()
{
	WORK_DIR="$1"
	if [[ -d "$WORK_DIR" ]];
	then
		AUDIO_COUNT=$(ls $WORK_DIR | grep ".ogg" | wc -l);
		if [ $AUDIO_COUNT != '0' ];
		then
			prepare_directory "$WORK_DIR";
			echo "Processing $AUDIO_COUNT files in $WORK_DIR. Please wait.";
			DATA_ARRAY+=($(for AUDIO_FILE in `ls $WORK_DIR | grep ".ogg"`;
			do
				FULLPATH="$WORK_DIR/$AUDIO_FILE";
				DBCOUNT=$(measure_db $FULLPATH);
				echo "$DBCOUNT"#"$AUDIO_FILE"
			done | sort -V));
			COUNT=1;
			for SORTED_DATA in ${DATA_ARRAY[*]};
			do
				printf -v NUM '%07d' $(( 10#$COUNT ));
				NAME=$(echo ${SORTED_DATA} | awk -F '#' '{print $2}');
				NEWNAME="${NUM}_${NAME}";
				NEWFULLPATH="${WORK_DIR}/Output/${NEWNAME}";
				if cp "${WORK_DIR}/${NAME}" "${NEWFULLPATH}";
				then
					echo "${NEWFULLPATH} added."
				fi;
				((++COUNT));
			done
			echo "Process finished.";
			exit 0;
		else
			echo "No audio file was found in $WORK_DIR";
			exit 1;
		fi;
	else
		echo "$WORK_DIR does not exist."
		exit 1;
	fi;
	unset WORK_DIR AUDIO_FILE FULLPATH DBCOUNT AUDIO_COUNT;
}

function revert_directory()
{
	WORK_DIR="$1"
	if [[ -d "$WORK_DIR" ]];
	then
		AUDIO_COUNT=$(ls $WORK_DIR | grep ".ogg" | wc -l);
		if [ $AUDIO_COUNT != '0' ];
		then
			prepare_revertdirectory "$WORK_DIR";
			echo "Processing $AUDIO_COUNT files in $WORK_DIR. Please wait.";
			for AUDIO_FILE in `ls $WORK_DIR | grep ".ogg"`;
			do
				FULLPATH="$WORK_DIR/$AUDIO_FILE";
				NEWNAME=$(echo "$AUDIO_FILE" | awk -F '_' '{print $2}');
				NEWFULLPATH="$WORK_DIR/Revert/$NEWNAME";
				if cp "${FULLPATH}" "${NEWFULLPATH}";
				then
					echo "${NEWFULLPATH} added."
				fi;
			done;
			echo "Process finished.";
			exit 0;
		else
			echo "No audio file was found in $WORK_DIR";
			exit 1;
		fi;
	else
		echo "$WORK_DIR does not exist."
		exit 1;
	fi;
	unset WORK_DIR AUDIO_FILE FULLPATH DBCOUNT AUDIO_COUNT;
}

OPTION1="$1";
OPTION2="$2";

if [ "$OPTION1" == 'revert' ];
then
	revert_directory "$OPTION2";
elif [ "$OPTION1" == 'convert' ];
then
	parse_directory "$OPTION2";
else
	echo "Invalid option.";
	exit 1;
fi;
