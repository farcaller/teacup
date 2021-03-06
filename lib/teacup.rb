require 'codependency'
require 'pathname'

module Teacup

  # - - - - - - - - - - - - - - - - - - -
  # Thanks to https://github.com/jeremyruppel/lotion/
  # for this bit.
  # - - - - - - - - - - - - - - - - - - -

  SOURCE = Dir[ File.expand_path( File.join(__FILE__, '../teacup/**/*.rb') ) ]
  FILES  = Codependency::Graph.new( SOURCE ).files.freeze
  PATHS  = FILES.map { |f| Pathname.new(f) }.freeze

  def self::Dependencies(file)
    path = Pathname.new(file).dirname
    PATHS.map { |p| p.relative_path_from(path).to_s }
  end

  # - - - - - - - - - - - - - - - - - - -
  # Config
  # - - - - - - - - - - - - - - - - - - -

  class << self

    def create(query)
      properties = current_sheet.query(query)
      constructor = properties.delete(:class)

      instance = if Proc === constructor
        instance = constructor.call
      else
        instance = constructor.new
      end

      apply_properties(properties, instance)
      instance
    end

    def style(query, instance)
      apply_properties(current_sheet.query(query), instance)
      instance
    end

    def apply_properties(properties, instance)
      clean_properties! properties

      properties.each do |key, value|
	if key == :title && UIButton === instance
	  instance.setTitle(value, forState: UIControlStateNormal)
	elsif instance.respond_to?(:"#{key}=")
	  instance.send(:"#{key}=", value)
	else
          $stderr.puts "Teacup WARN: Can't apply #{key} to #{instance.inspect}"
	end
      end
    end

    def clean_properties!(properties)
      return unless [:frame, :left, :top, :width, :height].any?(&properties.method(:key?))

      frame = properties.delete(:frame) || [[0,0],[0,0]]

      frame[0][0] = properties.delete(:left) || frame[0][0]
      frame[0][1] = properties.delete(:top) || frame[0][1]
      frame[1][0] = properties.delete(:width) || frame[1][0]
      frame[1][1] = properties.delete(:height) || frame[1][1]

      properties[:frame] = frame
    end

    def update(view)
      style(view.className, view)

      view.subviews.each(&method(:update))
    end

    def current_sheet
      if UIDevice.currentDevice.orientation == UIDeviceOrientationLandscapeLeft ||
         UIDevice.currentDevice.orientation == UIDeviceOrientationLandscapeRight
	    Teacup::StyleSheet::IPad
      else
	    Teacup::StyleSheet::IPadVertical
      end
    end
  end
end

require 'teacup/helpers/helpers.rb'
require 'teacup/version'
require 'teacup/contributors'
require 'teacup/helpers/helpers'
require 'teacup/style_sheet'
require 'teacup/contributors'
