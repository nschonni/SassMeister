'use strict'

config = require '../../config'

require 'angular'
require 'angular-ui-router'
require 'ngstorage'
require '../../../github-adapter'
require '../../sandbox'

angular.module 'SassMeister.index', [
  'ui.router'
  'ngStorage'
  'github-adapter'
  'SassMeister.sandbox'
]

.config ['$stateProvider', '$urlRouterProvider', '$locationProvider', ($stateProvider, $urlRouterProvider, $locationProvider) ->
  $locationProvider.html5Mode true

  template = require '../_application.jade'

  $stateProvider
    .state 'application.index',
      url: '^/'
      params:
        reset: false
      template: template
      controller: 'IndexController'
      resolve:
        data: ['$localStorage', '$stateParams', 'Sandbox', ($localStorage, $stateParams, Sandbox) ->
          if $stateParams.reset
            $localStorage.app = config.storageDefaults().app
            do Sandbox.reset

          _data = $localStorage.$default config.storageDefaults()

          # ngStorage's `$default` doesn't do a deep merge, so we need to apply the merge manually.
          # This ensures that new props added to the defaults are available to the app.
          # But... Turns out that `angular.merge` will over write existing keys, so `merge(data, defaults)` would erase any user values.
          # And, `merge(defaults, data)`—while it respects keys—breaks the automagic localStorage linkage.

          # So. Brute-force it with `extend`. Blech.
          _data.app = angular.extend config.storageDefaults().app, _data.app

          _data
        ]
]

.controller 'IndexController', ['$scope', '$rootScope', '$sassMeisterGist', '$localStorage', '$state', 'data', 'Sandbox', '$window', ($scope, $rootScope, $sassMeisterGist, $localStorage, $state, data, Sandbox, $window) ->
  $scope.$parent.app = data.app

  $rootScope._canEditGist = false

  $scope.createGist = (event) ->
    if event and event.preventDefault
      event.preventDefault()

    $window.ga('send', 'event', 'Gist', 'Create')

    $sassMeisterGist.create $scope, (gist) ->
      $scope.notify gist.id, 'is ready'

      $state.go '^.gist',
        id: gist.id
        gist: gist

  $scope.$on 'command-s', $scope.createGist

  Sandbox.onReady $scope.app
]

