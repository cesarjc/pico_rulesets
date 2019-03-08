<?php

function getSensors(){

    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL,"http://localhost:8080/sky/cloud/71wNMieVnpBJENYeF1FHpd/manage_sensors/sensors");
    
    // Receive server response ...
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $server_output = curl_exec($ch);

    curl_close ($ch);

    // Further processing ...
    $sensors = json_decode($server_output, true);
    var_dump($sensors);
    return $sensors;
}

function getTemperatures() {
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL,"http://localhost:8080/sky/cloud/71wNMieVnpBJENYeF1FHpd/manage_sensors/temperatures");
    
    // Receive server response ...
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $server_output = curl_exec($ch);

    curl_close ($ch);

    // Further processing ...
    $temperatures = json_decode($server_output, true);
    var_dump($temperatures);
}


function createNewSensor($name){
    
    $post_attributes = ["sensor_name" => $name];
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL,"http://localhost:8080/sky/event/71wNMieVnpBJENYeF1FHpd/asdf/sensor/new_sensor");
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS,  http_build_query($post_attributes));
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/x-www-form-urlencoded'));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $server_output = curl_exec($ch);

    curl_close ($ch);

    // Further processing ...
    $response = json_decode($server_output, true);
    var_dump($response);
}


function deleteSensor($name){
    $post_attributes = ["sensor_name" => $name];
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL,"http://localhost:8080/sky/event/71wNMieVnpBJENYeF1FHpd/asdf/sensor/unneeded_sensor");
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS,  http_build_query($post_attributes));
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/x-www-form-urlencoded'));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $server_output = curl_exec($ch);

    curl_close ($ch);

    // Further processing ...
    $response = json_decode($server_output, true);
    var_dump($response);
}

function sendTemperature($temperature, $eci) {
    $toSend = '{
        "genericThing":{
            "typeId":"2.1.2",
            "typeName":"generic.simple.temperature",
            "healthPercent":56.89,
            "heartbeatSeconds":10,
            "data":{
                "temperature":[
                    {
                        "name":"ambient temperature",
                        "transducerGUID":"28E3A5680900008D",
                        "units":"degrees",
                        "temperatureF": '.$temperature.',
                        "temperatureC":24.06
                    }
                ]
            }
        }
    }';

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL,"http://localhost:8080/sky/event/$eci/asdf/wovyn/heartbeat");
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS,  $toSend);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $server_output = curl_exec($ch);

    curl_close ($ch);

    // Further processing ...
    $response = json_decode($server_output, true);
    var_dump($response);


}
function getSensorProfile($eci){
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL,"http://localhost:8080/sky/cloud/$eci/sensor_profile/profile_info");
    
    // Receive server response ...
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $server_output = curl_exec($ch);

    curl_close ($ch);

    // Further processing ...
    $temperatures = json_decode($server_output, true);
    var_dump($temperatures);
}
function setSensorProfile($eci, $name = null, $location = null, $threshold = null, $number = null ){
    $post_attributes = ["name" => $name, "location" => $location, "threshold" => $threshold, $number => $number];
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL,"http://localhost:8080/sky/event/$eci/asdf/sensor/profile_updated");
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS,  http_build_query($post_attributes));
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/x-www-form-urlencoded'));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $server_output = curl_exec($ch);

    curl_close ($ch);

    // Further processing ...
    $response = json_decode($server_output, true);
    var_dump($response);
}

// Create new Colors class
$colors = new Colors();

// 1. creating multiple sensors and deleting at least one sensor. You only have one Wovyn device, so you'll only have one sensor pico 
//    that is actually connected to a device. Note: you'll have to reprogram the Wovyn sensor to send events to the new pico instead 
//    of the one you created manually. 
echo $colors->getColoredString("Available Sensors", "cyan") . "\n";
getSensors();
$sensorsToCreate = ["second_sensor", "third_sensor", "fourth_sensor"];
foreach($sensorsToCreate as $sensorName){
    echo $colors->getColoredString("Creating sensor $sensorName", "purple") . "\n";
    createNewSensor($sensorName);
}
sleep(1);
echo $colors->getColoredString("Available Sensors", "cyan") . "\n";
$sensorsAvailable = getSensors();

echo $colors->getColoredString("Deleting sensor second_sensor", "yellow") . "\n";
deleteSensor("second_sensor");
echo $colors->getColoredString("Available Sensors", "cyan") . "\n";
$sensorsAvailable = getSensors();

// 2. tests the sensors by ensuring they respond correctly to new temperature events. 

foreach($sensorsAvailable as $sensorName => &$eci){
    echo $colors->getColoredString("Sending temperature 80.7 to $sensorName => $eci", "purple") . "\n";
    sendTemperature(80.7, $eci);
}
foreach($sensorsAvailable as $sensorName => &$eci){
    echo $colors->getColoredString("Sending temperature 100.7 to $sensorName => $eci", "red") . "\n";
    sendTemperature(100.7, $eci);
}

// 3. tests the sensor profile to ensure it's getting set reliably.
foreach($sensorsAvailable as $sensorName => &$eci){
    echo $colors->getColoredString("Getting profile for  sensor $sensorName => $eci", "purple") . "\n";
    getSensorProfile($eci);
}
foreach($sensorsAvailable as $sensorName => &$eci){
    echo $colors->getColoredString("Setting profile for  sensor $sensorName => $eci", "purple") . "\n";
    setSensorProfile($eci, $name = "New home name", $location = "new home location", $threshold = "100", $number = "7575606680" );
}
foreach($sensorsAvailable as $sensorName => &$eci){
    echo $colors->getColoredString("Getting profile for  sensor $sensorName => $eci", "cyan") . "\n";
    getSensorProfile($eci);
}

echo $colors->getColoredString("Getting temperatures for all sensors", "cyan") . "\n";
getTemperatures();


?>




<?php

class Colors {
    private $foreground_colors = array();
    private $background_colors = array();

    public function __construct() {
        // Set up shell colors
        $this->foreground_colors['black'] = '0;30';
        $this->foreground_colors['dark_gray'] = '1;30';
        $this->foreground_colors['blue'] = '0;34';
        $this->foreground_colors['light_blue'] = '1;34';
        $this->foreground_colors['green'] = '0;32';
        $this->foreground_colors['light_green'] = '1;32';
        $this->foreground_colors['cyan'] = '0;36';
        $this->foreground_colors['light_cyan'] = '1;36';
        $this->foreground_colors['red'] = '0;31';
        $this->foreground_colors['light_red'] = '1;31';
        $this->foreground_colors['purple'] = '0;35';
        $this->foreground_colors['light_purple'] = '1;35';
        $this->foreground_colors['brown'] = '0;33';
        $this->foreground_colors['yellow'] = '1;33';
        $this->foreground_colors['light_gray'] = '0;37';
        $this->foreground_colors['white'] = '1;37';

        $this->background_colors['black'] = '40';
        $this->background_colors['red'] = '41';
        $this->background_colors['green'] = '42';
        $this->background_colors['yellow'] = '43';
        $this->background_colors['blue'] = '44';
        $this->background_colors['magenta'] = '45';
        $this->background_colors['cyan'] = '46';
        $this->background_colors['light_gray'] = '47';
    }

    // Returns colored string
    public function getColoredString($string, $foreground_color = null, $background_color = null) {
        $colored_string = "";

        // Check if given foreground color found
        if (isset($this->foreground_colors[$foreground_color])) {
            $colored_string .= "\033[" . $this->foreground_colors[$foreground_color] . "m";
        }
        // Check if given background color found
        if (isset($this->background_colors[$background_color])) {
            $colored_string .= "\033[" . $this->background_colors[$background_color] . "m";
        }

        // Add string and end coloring
        $colored_string .=  $string . "\033[0m";

        return $colored_string;
    }

    // Returns all foreground color names
    public function getForegroundColors() {
        return array_keys($this->foreground_colors);
    }

    // Returns all background color names
    public function getBackgroundColors() {
        return array_keys($this->background_colors);
    }
}


?>
