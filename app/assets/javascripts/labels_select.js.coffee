class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      projectId = $dropdown.data('project-id')
      labelUrl = $dropdown.data('labels')
      issueUpdateURL = $dropdown.data('issueUpdate')
      selectedLabel = $dropdown.data('selected')
      if selectedLabel?
        selectedLabel = selectedLabel.split(',')
      newLabelField = $('#new_label_name')
      newColorField = $('#new_label_color')
      showNo = $dropdown.data('show-no')
      showAny = $dropdown.data('show-any')
      defaultLabel = $dropdown.data('default-label')
      $selectbox = $dropdown.closest('.selectbox')
      $block = $selectbox.closest('.block')
      $value = $block.find('.value')
      $loading = $block.find('.block-loading').fadeOut()

      if newLabelField.length
        $newLabelCreateButton = $('.js-new-label-btn')
        $colorPreview = $('.js-dropdown-label-color-preview')
        $newLabelError = $dropdown.parent().find('.js-label-error')
        $newLabelError.hide()

        # Suggested colors in the dropdown to chose from pre-chosen colors
        $('.suggest-colors-dropdown a').on 'click', (e) ->

      issueURLSplit = issueURL.split('/') if issueURL?
      if issueURL
        labelHTMLTemplate = _.template(
            '<% _.each(labels, function(label){ %>'+
            '<a href="'+ 
            ['',issueURLSplit[1], issueURLSplit[2],''].join('/') +
            'issues?label_name=<%= label.title %>">'+
            '<span class="label color-label" '+
            'style="background-color: <%= label.color %>; '+
            'color: #FFFFFF">'+
            '<%= label.title %>'+
            '</span>'+
            '</a>'+
            '<% }); %>');
        labelNoneHTMLTemplate = _.template('<div class="light">None</div>')

      if newLabelField.length and $dropdown.hasClass 'js-extra-options'
        $('.suggest-colors-dropdown a').on "click", (e) ->
          e.preventDefault()
          e.stopPropagation()
          newColorField
            .val($(this).data('color'))
            .trigger('change')
          $colorPreview
            .css 'background-color', $(this).data('color')
            .parent()
            .addClass 'is-active'

        # Cancel button takes back to first page
        resetForm = ->
          newLabelField
            .val ''
            .trigger 'change'
          newColorField
            .val ''
            .trigger 'change'
          $colorPreview
            .css 'background-color', ''
            .parent()
            .removeClass 'is-active'

        $('.dropdown-menu-back').on 'click', ->
          resetForm()

        $('.js-cancel-label-btn').on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
          resetForm()
          $('.dropdown-menu-back', $dropdown.parent()).trigger 'click'

        # Listen for change and keyup events on label and color field
        # This allows us to enable the button when ready
        enableLabelCreateButton = ->
          if newLabelField.val() isnt '' and newColorField.val() isnt ''
            $newLabelCreateButton.enable()
          else
            $newLabelCreateButton.disable()

        newLabelField.on 'keyup change', enableLabelCreateButton

        newColorField.on 'keyup change', enableLabelCreateButton

        # Send the API call to create the label
        $newLabelCreateButton
          .disable()
          .on 'click', (e) ->
            e.preventDefault()
            e.stopPropagation()

            if newLabelField.val() isnt '' and newColorField.val() isnt ''
              $newLabelError.hide()
              $('.js-new-label-btn').disable()

              # Create new label with API
              Api.newLabel projectId, {
                name: newLabelField.val()
                color: newColorField.val()
              }, (label) ->
                $('.js-new-label-btn').enable()

                if label.message?
                  $newLabelError
                    .text label.message
                    .show()
                else
                  $('.dropdown-menu-back', $dropdown.parent()).trigger 'click'

      $dropdown.glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: labelUrl
          ).done (data) ->
            if $dropdown.hasClass 'js-extra-options'
              if showNo
                data.unshift(
                  id: 0
                  title: 'No Label'
                )

              if showAny
                data.unshift(
                  isAny: true
                  title: 'Any Label'
                )

              if data.length > 2
                data.splice 2, 0, 'divider'
            callback data

        renderRow: (label) ->
          if $.isArray(selectedLabel)
            selected = ''
            $.each selectedLabel, (i, selectedLbl) ->
              selectedLbl = selectedLbl.trim()
              if selected is '' and label.title is selectedLbl
                selected = 'is-active'
          else
            selected = if label.title is selectedLabel then 'is-active' else ''

          color = if label.color? then "<span class='dropdown-label-box' style='background-color: #{label.color}'></span>" else ""

          "<li>
            <a href='#' class='#{selected}'>
              #{color}
              #{label.title}
            </a>
          </li>"
        filterable: true
        search:
          fields: ['title']
        selectable: true

        toggleLabel: (selected) ->
          if selected and selected.title isnt 'Any Label'
            selected.title
          else
            defaultLabel
        fieldName: $dropdown.data('field-name')
        id: (label) ->
          if label.isAny?
            ''
          else if $dropdown.hasClass "js-filter-submit"
            label.title
          else
            label.id

        hidden: ->
          $selectbox.hide()
          $value.show()

        multiSelect: $dropdown.hasClass 'js-multiselect'

        clicked: ->
          page = $('body').data 'page'
          isIssueIndex = page is 'projects:issues:index'
          isMRIndex = page is page is 'projects:merge_requests:index'

          if $dropdown.hasClass('js-filter-submit') and (isIssueIndex or isMRIndex)
            Issues.filterResults $dropdown.closest('form')
          else if $dropdown.hasClass 'js-filter-submit'
            $dropdown.closest('form').submit()
          else
            selected = $dropdown
              .closest('.selectbox')
              .find("input[name='#{$dropdown.data('field-name')}']")
              .map(->
                @value
              ).get()
            # need inline-block here instead of show, 
            # which will default to the element's style in this case inline.
            selected = if selected.length then selected else ['']
            $loading
              .fadeIn()
            $.ajax(
              type: 'PUT'
              url: issueURL
              data:
                issue: 
                  label_ids:  selected
            ).done (data) ->
              $loading.fadeOut()
              $selectbox.hide()
              if not data.labels.length
                template = labelNoneHTMLTemplate()
              else
                template = labelHTMLTemplate(data)
              href = $value
                      .show()
                      .html(template)
      )
