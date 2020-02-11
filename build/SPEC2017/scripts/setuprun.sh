#!/bin/bash

if [ ! "${1}" == "test" ] && [ ! "${1}" == "train" ] && [ ! "${1}" == "ref" ]; then
  echo "Please provide input configuration [test,train,refspeed] for setting up run directories. For Example: ./setuprun.sh ref rate "
  exit
fi


if [ ! "${2}" == "rate" ] && [ ! "${2}" == "speed" ]; then
  echo "Please provide version  [rate,speed] for setting up run directories. For Example: ./setuprun.sh ref rate "
  exit
fi

if [ "${1}" == "ref" ] && [ "${2}" == "rate" ]; then
	inputsize="refrate"
elif [ "${1}" == "ref" ] && [ "${2}" == "speed" ]; then
	inputsize="refspeed"
else
	inputsize=${1}
fi

source /project/gllvm/enable
BUILD_DIR=`pwd`


if [ ! -d "../../bitcodes/LLVM9.0/SPEC2017" ]; then
  mkdir ../../bitcodes/LLVM9.0/SPEC2017
fi

cd ${BUILD_DIR}

if [ ! -d "${BUILD_DIR}/benchmarks/" ]; then
  mkdir ${BUILD_DIR}/benchmarks
fi

if [ ! -d "${BUILD_DIR}/SPEC2017" ]; then
	echo "Please run ./setup.sh and ./compile.sh first to install SPEC2017 and build benchmarks."
	exit
fi


#Setup Run directories with runcpu
cd SPEC2017
source shrc
runcpu --loose --size ${inputsize} --tune peak -a setup --config gclang pure_c_cpp_$2


#Copy Run directories and extract bitcodes
BENCHMARKS_DIR=${BUILD_DIR}/benchmarks


if [ "${2}" == "rate" ]; then
	key="_r"
elif [ "${2}" == "speed" ]; then
	key="_s"
else
	key=""
fi

for benchmark_string in `sed 1d ${BUILD_DIR}/pure_c_cpp_${2}.bset | grep ${key}`; do
	benchmark="$( echo $benchmark_string | awk -F'.' '{print $2}')"
	if [ ! -d "${BENCHMARKS_DIR}/${benchmark}" ]; then
		mkdir ${BENCHMARKS_DIR}/${benchmark}
	fi
	if [ -d "${BENCHMARKS_DIR}/${benchmark}/${inputsize}" ]; then
		rm -r ${BENCHMARKS_DIR}/${benchmark}/${inputsize}
	fi
	go ${benchmark} run
	cp -r run_peak_${inputsize}_gclang.0000 ${BENCHMARKS_DIR}/${benchmark}/${inputsize}
	cd ${BENCHMARKS_DIR}/${benchmark}
	if [ "${benchmark}" == "xalancbmk_r" ]; then
		mv ${inputsize}/cpuxalan_r_peak.gclang ${BENCHMARKS_DIR}/${benchmark}/${benchmark}
	else
		mv ${inputsize}/${benchmark}_peak.gclang ${BENCHMARKS_DIR}/${benchmark}/${benchmark}
	fi

	
	lastline="`tail -n 1 ${inputsize}/speccmds.cmd`"
	arguments="$( echo $lastline | awk -F'peak.gclang ' '{print $2}')"
	echo '#!/bin/bash' > run_${inputsize}.sh
	echo "cd `pwd`/${inputsize}" >> run_${inputsize}.sh
	echo "./../${benchmark} ${arguments}" >> run_${inputsize}.sh
	chmod +x run_${inputsize}.sh
done
echo "-----------------------------------------------------------"
echo "Run directories created at ${BENCHMARKS_DIR} contain respective binaries and bitcodes. Run workload '${1}' with ./run.sh found at respective workload directories."  
 

echo "DONE" 

exit

