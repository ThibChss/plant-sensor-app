import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js";
import "chartjs-adapter-date-fns"

Chart.register(...registerables);

export default class extends Controller {
  static values = { readings: Array, threshold: Number }

  connect() {
    this.renderChart()
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }

  renderChart() {
    const canvas = this.element.querySelector("canvas")
    const readings = this.readingsValue
    const threshold = this.thresholdValue

    // Brand configuration
    const forestGreen = "#346739"
    const mossGreen = "#79AE6F"
    const sageGreen = "#9FCB98"

    this.chart = new Chart(canvas, {
      type: "line",
      data: {
        datasets: [
          {
            label: "Moisture",
            data: readings,
            borderColor: forestGreen,
            backgroundColor: (context) => {
              const chart = context.chart;
              const {ctx, chartArea} = chart;
              if (!chartArea) return null;
              const gradient = ctx.createLinearGradient(0, chartArea.bottom, 0, chartArea.top);
              gradient.addColorStop(0, "rgba(236, 244, 232, 0)"); // pulse-mist transparent
              gradient.addColorStop(1, "rgba(52, 103, 57, 0.1)"); // pulse-forest soft
              return gradient;
            },
            borderWidth: 3,
            pointRadius: 0, // Cleaner look without points
            pointHoverRadius: 6,
            pointHoverBackgroundColor: forestGreen,
            pointHoverBorderColor: "#fff",
            pointHoverBorderWidth: 2,
            tension: 0.4, // Smooth curves
            fill: true
          },
          {
            label: "Threshold",
            data: readings.map(r => ({ x: r.x, y: threshold })),
            borderColor: "rgba(244, 63, 94, 0.4)", // rose-500
            borderWidth: 1,
            borderDash: [5, 5],
            pointRadius: 0,
            fill: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { intersect: false, mode: 'index' },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: forestGreen,
            titleFont: { family: 'Alegreya Sans', size: 12, weight: '900' },
            bodyFont: { family: 'Palanquin', size: 11 },
            padding: 12,
            cornerRadius: 16,
            displayColors: false,
            callbacks: {
              label: (item) => ` ${item.raw.y}% Humidité`
            }
          }
        },
        scales: {
          x: {
            type: "time",
            time: { unit: "day", displayFormats: { day: "dd MMM" } },
            ticks: {
              color: "rgba(121, 174, 111, 0.5)",
              font: { family: 'Palanquin', size: 9, weight: '700' },
              maxRotation: 0
            },
            grid: { display: false }
          },
          y: {
            min: 0,
            max: 100,
            ticks: {
              stepSize: 20,
              callback: v => v + "%",
              color: "rgba(121, 174, 111, 0.5)",
              font: { family: 'Alegreya Sans', size: 10, weight: '700' }
            },
            grid: {
              color: "rgba(159, 203, 152, 0.1)",
              drawBorder: false
            }
          }
        }
      }
    })
  }
}
