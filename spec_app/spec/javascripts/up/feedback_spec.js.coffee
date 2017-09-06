describe 'up.feedback', ->

  u = up.util

  beforeEach ->
    up.modal.config.openAnimation = 'none'
    up.modal.config.closeAnimation = 'none'

  describe 'unobtrusive behavior', ->

    describe '.up-current', ->

      it 'marks a link as .up-current if it links to the current URL', ->
        spyOn(up.browser, 'url').and.returnValue('/foo')
        $currentLink = up.hello(affix('a[href="/foo"]'))
        $otherLink = up.hello(affix('a[href="/bar"]'))
        expect($currentLink).toHaveClass('up-current')
        expect($otherLink).not.toHaveClass('up-current')

      it 'marks any link as .up-current if its up-href attribute matches the current URL', ->
        spyOn(up.browser, 'url').and.returnValue('/foo')
        $currentLink = up.hello(affix('span[up-href="/foo"]'))
        $otherLink = up.hello(affix('span[up-href="/bar"]'))
        expect($currentLink).toHaveClass('up-current')
        expect($otherLink).not.toHaveClass('up-current')

      it 'matches the current and destination URLs if they only differ by a trailing slash', ->
        spyOn(up.browser, 'url').and.returnValue('/foo')
        $currentLink = up.hello(affix('span[up-href="/foo/"]'))
        expect($currentLink).toHaveClass('up-current')

      it 'does not match the current and destination URLs if they differ in the search', ->
        spyOn(up.browser, 'url').and.returnValue('/foo?q=1')
        $currentLink = up.hello(affix('span[up-href="/foo?q=2"]'))
        expect($currentLink).not.toHaveClass('up-current')

      it 'marks any link as .up-current if any of its space-separated up-alias values matches the current URL', ->
        spyOn(up.browser, 'url').and.returnValue('/foo')
        $currentLink = up.hello(affix('a[href="/x"][up-alias="/aaa /foo /bbb"]'))
        $otherLink = up.hello(affix('a[href="/y"][up-alias="/bar"]'))
        expect($currentLink).toHaveClass('up-current')
        expect($otherLink).not.toHaveClass('up-current')

      it 'does not throw if the current location does not match an up-alias wildcard (bugfix)', ->
        inserter = -> up.hello(affix('a[up-alias="/qqqq*"]'))
        expect(inserter).not.toThrow()

      it 'does not highlight a link to "#" (commonly used for JS-only buttons)', ->
        $link = up.hello(affix('a[href="#"]'))
        expect($link).not.toHaveClass('up-current')

      it 'marks URL prefixes as .up-current if an up-alias value ends in *', ->
        spyOn(up.browser, 'url').and.returnValue('/foo/123')
        $currentLink = up.hello(affix('a[href="/x"][up-alias="/aaa /foo/* /bbb"]'))
        $otherLink = up.hello(affix('a[href="/y"][up-alias="/bar"]'))
        expect($currentLink).toHaveClass('up-current')
        expect($otherLink).not.toHaveClass('up-current')

      it 'allows to configure a custom "current" class, but always also sets .up-current', ->
        up.feedback.config.currentClasses = ['highlight']
        spyOn(up.browser, 'url').and.returnValue('/foo')
        $currentLink = up.hello(affix('a[href="/foo"]'))
        expect($currentLink).toHaveClass('highlight up-current')

      describeCapability 'canPushState', ->

        it 'marks a link as .up-current if it links to the current URL, but is missing a trailing slash', asyncSpec (next) ->
          $link = affix('a[href="/foo"][up-target=".main"]')
          affix('.main')
          Trigger.clickSequence($link)

          next =>
            @respondWith
              responseHeaders: { 'X-Up-Location': '/foo/' }
              responseText: '<div class="main">new-text</div>'

          next =>
            expect($link).toHaveClass('up-current')

        it 'marks a link as .up-current if it links to the current URL, but has an extra trailing slash', asyncSpec (next) ->
          $link = affix('a[href="/foo/"][up-target=".main"]')
          affix('.main')
          Trigger.clickSequence($link)

          next =>
            @respondWith
              responseHeaders: { 'X-Up-Location': '/foo' }
              responseText: '<div class="main">new-text</div>'

          next =>
            expect($link).toHaveClass('up-current')

        it 'marks a link as .up-current if it links to an URL currently shown either within or below the modal', asyncSpec (next) ->
          up.history.replace('/foo')

          $backgroundLink = affix('a[href="/foo"]')
          $modalLink = affix('a[href="/bar"][up-modal=".main"]')
          $unrelatedLink = affix('a[href="/baz]')

          Trigger.clickSequence($modalLink)

          next =>
            @respondWith('<div class="main">new-text</div>')

          next =>
            expect($backgroundLink).toHaveClass('up-current')
            expect($modalLink).toHaveClass('up-current')
            expect($unrelatedLink).not.toHaveClass('up-current')
            next.await up.modal.close()

          next =>
            expect($backgroundLink).toHaveClass('up-current')
            expect($modalLink).not.toHaveClass('up-current')
            expect($unrelatedLink).not.toHaveClass('up-current')

        it 'marks a link as .up-current if it links to the URL currently either within or below the popup', asyncSpec (next) ->
          up.history.replace('/foo')

          $backgroundLink = affix('a[href="/foo"]')
          $popupLink = affix('a[href="/bar"][up-popup=".main"]')
          $unrelatedLink = affix('a[href="/baz]')

          next =>
            Trigger.clickSequence($popupLink)

          next =>
            @respondWith('<div class="main">new-text</div>')

          next =>
            expect($backgroundLink).toHaveClass('up-current')
            expect($popupLink).toHaveClass('up-current')
            expect($unrelatedLink).not.toHaveClass('up-current')

            next.await up.popup.close()

          next =>
            expect($backgroundLink).toHaveClass('up-current')
            expect($popupLink).not.toHaveClass('up-current')
            expect($unrelatedLink).not.toHaveClass('up-current')

        it 'changes .up-current marks as the URL changes'

    describe '.up-active', ->

      describeCapability 'canPushState', ->

        it 'marks clicked links as .up-active until the request finishes', asyncSpec (next) ->
          $link = affix('a[href="/foo"][up-target=".main"]')
          affix('.main')
          Trigger.clickSequence($link)

          next =>
            expect($link).toHaveClass('up-active')
            @respondWith('<div class="main">new-text</div>')

          next =>
            expect($link).not.toHaveClass('up-active')

        it 'marks links with [up-instant] on mousedown as .up-active until the request finishes', asyncSpec (next) ->
          $link = affix('a[href="/foo"][up-instant][up-target=".main"]')
          affix('.main')
          Trigger.mousedown($link)

          next => expect($link).toHaveClass('up-active')
          next => @respondWith('<div class="main">new-text</div>')
          next => expect($link).not.toHaveClass('up-active')

        it 'prefers to mark an enclosing [up-expand] click area', asyncSpec (next) ->
          $area = affix('div[up-expand] a[href="/foo"][up-target=".main"]')
          up.hello($area)
          $link = $area.find('a')
          affix('.main')
          Trigger.clickSequence($link)

          next =>
            expect($link).not.toHaveClass('up-active')
            expect($area).toHaveClass('up-active')
          next =>
            @respondWith('<div class="main">new-text</div>')
          next =>
            expect($area).not.toHaveClass('up-active')

        it 'marks clicked modal openers as .up-active while the modal is loading', asyncSpec (next) ->
          $link = affix('a[href="/foo"][up-modal=".main"]')
          affix('.main')
          Trigger.clickSequence($link)

          next => expect($link).toHaveClass('up-active')
          next => @respondWith('<div class="main">new-text</div>')
          next => expect($link).not.toHaveClass('up-active')

        it 'removes .up-active from a clicked modal opener if the target is already preloaded (bugfix)', asyncSpec (next) ->
          $link = affix('a[href="/foo"][up-modal=".main"]')
          up.proxy.preload($link)

          next => @respondWith('<div class="main">new-text</div>')
          next => Trigger.clickSequence($link)
          next =>
            expect('.up-modal .main').toHaveText('new-text')
            expect($link).not.toHaveClass('up-active')

        it 'removes .up-active from a clicked link if the target is already preloaded (bugfix)', asyncSpec (next) ->
          $link = affix('a[href="/foo"][up-target=".main"]')
          affix('.main')
          up.proxy.preload($link)

          next => @respondWith('<div class="main">new-text</div>')
          next => Trigger.clickSequence($link)
          next =>
            expect('.main').toHaveText('new-text')
            expect($link).not.toHaveClass('up-active')

