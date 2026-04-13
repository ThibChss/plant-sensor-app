module Components
  class PlantInfo < Components::Base
    COLOR_CLASSES = {
      "orange" => {
        bg: "bg-orange-50/80",
        text: "text-orange-500"
      },
      "purple" => {
        bg: "bg-purple-50/80",
        text: "text-purple-500"
      },
      "emerald" => {
        bg: "bg-emerald-50/80",
        text: "text-emerald-500"
      },
      "amber" => {
        bg: "bg-amber-50/80",
        text: "text-amber-500"
      },
      "blue" => {
        bg: "bg-blue-50/80",
        text: "text-blue-500"
      },
      "yellow" => {
        bg: "bg-yellow-50/80",
        text: "text-yellow-500"
      }
    }.freeze

    private_constant :COLOR_CLASSES

    def initialize(icon:, size_label:, color:)
      @icon = icon
      @size_label = size_label
      @color = COLOR_CLASSES.fetch(color, COLOR_CLASSES["blue"])
    end

    def view_template(&)
      div(class: "bg-white/70 backdrop-blur-sm rounded-[2rem] p-5 border border-white flex items-center gap-3") do
        div(class: "shrink-0 w-10 h-10 #{@color[:bg]} rounded-2xl flex items-center justify-center #{@color[:text]}") do
          view_context.icon(@icon, class: "w-5 h-5")
        end
        div(class: "flex flex-col justify-center") do
          span(class: "text-[9px] font-bold text-pulse-moss uppercase tracking-widest opacity-40 leading-none mb-1 font-palanquin") do
            plain @size_label
          end
          div(class: "flex items-baseline font-alegreya text-sm font-black text-pulse-forest leading-none", &)
        end
      end
    end
  end
end
