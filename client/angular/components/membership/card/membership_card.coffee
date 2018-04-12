Records        = require 'shared/services/records.coffee'
AbilityService = require 'shared/services/ability_service.coffee'
ModalService   = require 'shared/services/modal_service.coffee'
RecordLoader   = require 'shared/services/record_loader.coffee'

angular.module('loomioApp').directive 'membershipCard', ->
  scope: {group: '='}
  restrict: 'E'
  templateUrl: 'generated/components/membership/card/membership_card.html'
  replace: true
  controller: ['$scope', ($scope) ->
    $scope.loader = new RecordLoader
      collection: 'memberships'
      per: 1
      params:
        group_id: $scope.group.id
    $scope.loader.fetchRecords() if AbilityService.canViewMemberships($scope.group)

    $scope.toggleSearch = ->
      $scope.fragment = ''
      $scope.searchOpen = !$scope.searchOpen
      setTimeout -> document.querySelector('.membership-card__search input').focus()

    $scope.showLoadMore = ->
      !$scope.fragment

    $scope.canAddMembers = ->
      AbilityService.canAddMembers($scope.group)

    $scope.memberships = ->
      if $scope.fragment
        _.filter $scope.group.memberships(), (membership) =>
          _.contains membership.userName().toLowerCase(), $scope.fragment.toLowerCase()
      else
        $scope.group.memberships()

    $scope.invite = ->
      ModalService.open 'AnnouncementModal', announcement: ->
        Records.announcements.buildFromModel($scope.group)

    $scope.fetchMemberships = ->
      return unless $scope.fragment
      Records.memberships.fetchByNameFragment($scope.fragment, $scope.group.key)

  ]
