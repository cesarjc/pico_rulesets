angular.module('profile', [])
.controller('MainCtrl', [
  '$scope','$http',
  function($scope,$http){
    $scope.profile_info = {};
    baseURL = "http://localhost:8080/sky/cloud/LaYgFM6Qivsfw6GZn6pm6F/sensor_profile/profile_info";
    $scope.getProfileInfo = function() {
        var gUrl = baseURL ;
        return $http.get(gUrl).then(function (response){
            angular.copy(response.data, $scope.profile_info);
			
            console.log("status:" + response.status);
            console.log($scope.temperatures)
		}).catch(function(response) {
		  console.error('Error occurred:', response.status, response.data);});
    }

    $scope.submitForm = function(){
        // $http({
        //     url: 'http://localhost:8080/sky/cloud/LaYgFM6Qivsfw6GZn6pm6F/sensor_profile/profile_inforequest-url',
        //     method: "POST",
        //     data: $scope.profile_info
        // })
        // $http.post()
        // .then(function(response) {
        //         console.log("succesfully updated")
        // }, 
        // function(response) { // optional
        //         console.log("Error updating")
        // });
        

        form_data = getFormData($scope.profile_info)

        pUrl = "http://localhost:8080/sky/event/LaYgFM6Qivsfw6GZn6pm6F/asdf/sensor/profile_updated"
        $.post(pUrl,$scope.profile_info,
            function(data,status){
                alert("Successfully updated information");
            }
            ,)

    }

    function getFormData(object) {
        const formData = new FormData();
        Object.keys(object).forEach(key => formData.append(key, object[key]));
        return formData;
    }
    
    
    $scope.getProfileInfo();
  }
]);
