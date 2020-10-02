#!/bin/bash
project="braza-android"
cd /Users/eric/StudioProjects/${project}
output="../AndroidCommandLineTools/${project}-test-output.txt"

# clean up output from previous runs
if [ -f $output ]
then
rm $output
fi

# run unit tests device independant
./gradlew testDebugUnitTest >> $output
if [ $? -ne 0 ]
then
echo "**********Unit Tests Failed**********"
cat $output
echo "**********FIX UNIT TESTS FIRST*******"
exit
fi

FAILED=0
for emulator in EricPixel_API_28 Nexus_5_API_26 Pixel_3a_API_30 Pixel_XL_API_29 Small_Nexus_API_28
do
  echo "Running Tests for Emulator ${emulator}"
  echo "*********TESTS ${emulator}*************" >> $output
  # start up emulator
  emulator -avd $emulator -netdelay none -netspeed full &
  PID=$!
  sleep 10
  # run the tests
  ./gradlew connectedDebugAndroidTest >> $output
  if [ $? -ne 0 ]
  then
    echo "!!!!!!! $emulator Connected Tests Failed !!!!!!"
    FAILED=1
  fi
  # grab the screenshots from device
  ../AndroidCommandLineTools/ADB-PullScreenshots.sh
  # organize screen shots
  if [ -d ../AndroidCommandLineTools/screenshots/Previous_${emulator} ]
  then
    rm -rf ../AndroidCommandLineTools/screenshots/Previous_${emulator}
  fi
  if [ -d ../AndroidCommandLineTools/screenshots/${emulator} ]
  then
    mv ../AndroidCommandLineTools/screenshots/${emulator} ../AndroidCommandLineTools/screenshots/Previous_${emulator}
  fi
  mkdir ../AndroidCommandLineTools/screenshots/${emulator}
  mv ../AndroidCommandLineTools/screenshots/*.png ../AndroidCommandLineTools/screenshots/${emulator}
  # uninstall and shut down emulator
  ../AndroidCommandLineTools/ADB-Uninstall.sh > /dev/null 2>&1
  kill $PID
  sleep 6
done

if [ $FAILED -eq 1 ]
then
  cat ${project}-test-output.txt
fi
