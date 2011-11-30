# Title: SoundCloud plugin for Jekyll
# Author: Nick Fisher (http://spadgos.github.com)
# Description:
#   Given a SoundCloud track, user, group, app or set, this will insert a SoundCloud HTML5 widget, with automatic Flash
#   fallback for older browsers
#
# Syntax: {% soundcloud type id [option=value [option=value [...]]]%}
#
# type can be one of "tracks", "groups", "users", "favorites", "apps", or "playlists".
# id should be the id of the given resource. A username can also be used in the case of "users" or "favorites"
# options are:
#
# auto_play=<true|false>
# buying=<true|false>
# download=<true|false>
# sharing=<true|false>
# show_artwork=<true|false>
# show_bpm=<true|false>
# show_comments=<true|false>
# show_playcount=<true|false>
# show_user=<true|false>
# single_active=<true|false>
# start_track=<number>
# color=<hexcode>

module Jekyll
  class SoundCloud < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      if /(?<type>\w+)\s+(?<id>\w+)(?:\s+(?<options>.*))?/ =~ markup
        @type  = type
        @id    = id
        @options = ([] unless options) || options.split(" ")
      end
      @markup = markup
    end

    def render(context)
      if @type and @id
        @height = (450 unless @type == 'tracks') || 166
        @resource = (@type unless @type === 'favorites') || 'users'
        @extra = ("" unless @type === 'favorites') || '%2Ffavorites'
        @joined_options = @options.join("&amp;")
        "<iframe width=\"100%\" height=\"#{@height}\" scrolling=\"no\" frameborder=\"no\" src=\"http://w.soundcloud.com/player/?url=http%3A%2F%2Fapi.soundcloud.com%2F#{@resource}%2F#{@id}#{@extra}&amp;#{@joined_options}\"></iframe>"
      else
        "Error processing input, expected syntax: {% soundcloud type id [options...] %} received: #{@markup}"
      end
    end
  end
end

Liquid::Template.register_tag('soundcloud', Jekyll::SoundCloud)

