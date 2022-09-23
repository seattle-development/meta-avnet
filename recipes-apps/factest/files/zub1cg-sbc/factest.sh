#!/bin/bash

# Check if there are any switches such unattended mode
unattended=0

if [[ $# -gt 0 ]]
then
      for var in "$@"
      do
         if [[ $var -eq "-u" ]]
         then
            unattended=1
         fi
      done
fi

FACTEST_SCRIPTS_DIR=/home/root/factest_scripts
LOCAL_RESULTS_FILE=last_factest_results.log

# In unattended mode we don't write the results to local file system
# to prevent prevent this from filling up the disk
if [[ $unattended -eq 1 ]]
then
   LOCAL_RESULTS_FILE=/dev/null
fi


QSPI_RESULTS_FILE=factest_results.log
source $FACTEST_SCRIPTS_DIR/qspi_utils.sh

nb_passed=0
nb_failed=0

cecho(){
    RED="\033[0;31m"
    GREEN="\033[0;32m"  # <-- [0 means not bold
    YELLOW="\033[1;33m" # <-- [1 means bold
    CYAN="\033[1;36m"
    # ... Add more colors if you like

    NC="\033[0m" # No Color

    # printf "${(P)1}${2} ${NC}\n" # <-- zsh
    printf "${!1}${2} ${NC}\n" # <-- bash
}
execute_command_test () {
   desc=$1
   command=$2

   cecho "CYAN" "\n--------- $desc ---------\n"
   $command
   status=$?

   if [ $status -ne 0 ]
   then
      nb_failed=$((nb_failed+1))
      cecho "RED" "\n--------- $desc - FAIL ---------"
   else
      nb_passed=$((nb_passed+1))
      cecho "GREEN" "\n--------- $desc - PASS ---------"
   fi

   return $status
}

execute_script_test () {
   desc=$1
   script=$2

   cecho "CYAN" "\n--------- $desc ---------\n"
   if [[ $unattended -eq 1 ]]
   then
      /bin/sh $script -u
   else
      /bin/sh $script
   fi

   status=$?

   if [ $status -ne 0 ]
   then
      nb_failed=$((nb_failed+1))
      cecho "RED" "\n--------- $desc - FAIL ---------"
   else
      nb_passed=$((nb_passed+1))
      cecho "GREEN" "\n--------- $desc - PASS ---------"
   fi

   return $status
}

print_results () {
   nb_test=$((nb_passed + nb_failed))
      echo -e "\n\n-----------------------------------"
      echo -e "------------- RESULTS -------------"
      cecho "CYAN" " Ran:    $nb_test tests"
      cecho "GREEN" " Passed: $nb_passed tests"
      cecho "RED" " Failed: $nb_failed tests"
      echo -e "-----------------------------------\n"
}


{
   if [[ $unattended -eq 1 ]]
   then
      # In unattended mode, we don't write the results to the QSPI
      cecho "CYAN" "\n--------- Running test suite in unattended mode ---------\n"
   else
      QSPI_STATUS=0
      execute_command_test "QSPI TEST (mount user partition)" "qspi_mount_user_part"
      if [[ $? -ne 0 ]]
      then
         QSPI_STATUS=1
      fi
   fi


   execute_script_test "Test Buttons and LEDs" $FACTEST_SCRIPTS_DIR/buttons_and_leds_test.sh
   execute_script_test "Test Click Module interface" $FACTEST_SCRIPTS_DIR/click_test.sh
   execute_script_test "Test SyZyGY interfaces" $FACTEST_SCRIPTS_DIR/szg_lb_test.sh
   execute_script_test "Test Internal Sensors" $FACTEST_SCRIPTS_DIR/internal_sensors_test.sh
   execute_script_test "Test SYSMON" $FACTEST_SCRIPTS_DIR/sysmon_test.sh
   execute_script_test "Test Ethernet Interface" $FACTEST_SCRIPTS_DIR/ethernet_test.sh
   execute_script_test "Test USB Interface" $FACTEST_SCRIPTS_DIR/usb_test.sh
   execute_script_test "Test RTC" $FACTEST_SCRIPTS_DIR/rtc_test.sh

   print_results
} > >(tee -a "$LOCAL_RESULTS_FILE") 2>&1

sync

# Only copy the results to the QSPI if test is running in unattended mode
if [[ $unattended -eq 0 ]]
then
   if [[ $QSPI_STATUS -eq 0 ]]
   then
      echo "Copying Test Results to QSPI"
      copy_log_file_to_qspi $LOCAL_RESULTS_FILE $QSPI_RESULTS_FILE
   else
      echo "QSPI TEST Failed, log file can be found on the sd card: /home/root/$LOCAL_RESULTS_FILE"
   fi
fi
