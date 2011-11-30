# Title: SoundCloud plugin for Jekyll
# Author: Nick Fisher (http://spadgos.github.com)
# Description:
#   Given a SoundCloud track, user, group, app or set, this will insert a SoundCloud HTML5 widget, with automatic Flash
#   fallback for older browsers
#
# Syntax: {% soundcloud type id %}
#
# type can be one of "tracks", "groups", "users", "favorites", "apps", or "sets".
# id should be the id of the given resource. A username can also be used in the case of "users" or "favorites"
#

module Jekyll
  class SoundCloud < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      if /(?<type>\w+)\s+(?<id>\w+)/ =~ markup
        @type  = type
        @id    = id
      end
    end

    def render(context)
      if @type and @id
        @height = (450 unless @type == 'tracks') || 166
        @resource = (@type unless @type === 'favorites') || 'users'
        @extra = ("" unless @type === 'favorites') || '%2Ffavorites'
        "<iframe width=\"100%\" height=\"#{@height}\" scrolling=\"no\" frameborder=\"no\" src=\"http://w.soundcloud.com/player/?url=http%3A%2F%2Fapi.soundcloud.com%2F#{@resource}%2F#{@id}#{@extra}&amp;auto_play=false&amp;show_artwork=false&amp;color=ff7700\"></iframe>"
      else
        "Error processing input, expected syntax: {% soundcloud type id %}"
      end
    end
  end
end

Liquid::Template.register_tag('soundcloud', Jekyll::SoundCloud)
