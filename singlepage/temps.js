angular.module('temperatures', [])
.controller('MainCtrl', [
  '$scope','$http','$interval',
  function($scope,$http, $interval){
    $scope.temperatures = [];
    $scope.temp_violations = [];
    // $scope.eci = "cj1i5z6240003s5ddpomhahb6";
    baseURL = "http://localhost:8080/sky/cloud/LaYgFM6Qivsfw6GZn6pm6F/temperature_store";
    $scope.getAllTemps = function() {
        var gUrl = baseURL + "/temperatures";
        return $http.get(gUrl).then(function (response){
            angular.copy(response.data, $scope.temperatures);
			
            
		}).catch(function(response) {
		  console.error('Error occurred:', response.status, response.data);});
    }
    
    $scope.getViolations = function() {
      var gUrl = baseURL + "/threshold_violations";
        return $http.get(gUrl).then(function (response){
            angular.copy(response.data, $scope.temp_violations);
			
		  }).catch(function(response) {
		  console.error('Error occurred:', response.status, response.data);});
    }
    $interval(function() {
      $scope.getViolations();
      $scope.getAllTemps();  
    }, 1000);
    
    
  }
]);
