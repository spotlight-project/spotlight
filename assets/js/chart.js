import uPlot from 'uplot'

let chart = null;

function paths(u, sidx, i0, i1) {
	const s = u.series[sidx];
	const xdata = u.data[0];
	const ydata = u.data[sidx];
	const scaleX = 'x';
	const scaleY = s.scale;

	const stroke = new Path2D();

  let step = 1; // 1 second, hard code for now, but we can make this dynamic in the future

  const x_width = Math.abs((u.valToPos(step, scaleX, true) - u.valToPos(2 * step, scaleX, true)) / 2);

	stroke.moveTo(
		Math.round(u.valToPos(xdata[0], scaleX, true)),
		Math.round(u.valToPos(ydata[0], scaleY, true))
	);

	for (let i = i0; i < i1; i++) {
		let x0 = Math.round(u.valToPos(xdata[i], scaleX, true));
		let y0 = Math.round(u.valToPos(ydata[i], scaleY, true));
		let x1 = Math.round(u.valToPos(xdata[i + 1], scaleX, true));
		let y1 = Math.round(u.valToPos(ydata[i + 1], scaleY, true));

    stroke.lineTo(x0 - x_width, y0);
    stroke.lineTo(x1 - x_width, y0);

		if (i == i1 - 1) {
      // the last bit
			stroke.lineTo(x1 - x_width, y1);
			stroke.lineTo(x1, y1);
		}
	}

	const fill = new Path2D(stroke);

	let minY = Math.round(u.valToPos(u.scales[scaleY].min, scaleY, true));
	let minX = Math.round(u.valToPos(u.scales[scaleX].min, scaleX, true));
	let maxX = Math.round(u.valToPos(u.scales[scaleX].max, scaleX, true));

	fill.lineTo(maxX, minY);
	fill.lineTo(minX, minY);

	return {
		stroke,
		fill,
	};
}

function format_time(time_ms) {
  if (time_ms === null) {
    return "";
  } else if (time_ms < 1) {
    return (time_ms * 1000).toPrecision(3) + " µs";
  } else if (time_ms < 1000) {
    return time_ms.toPrecision(3) + " ms";
  } else {
    return (time_ms / 1000).toPrecision(3) + " s";
  }
}

function format_requests(requests) {
  if (requests === null) {
    return "";
  } else if (requests < 1000) {
    return requests + " reqs"
  } else if (requests < 1000000) {
    return requests / 1000 + "k reqs"
  } else {
    return requests / 1000000 + "M reqs"
  }
}

function create_chart(data, scale) {
	let rect = { width: window.innerWidth * 0.6, height: 400 };

  let scales = {};

  if (scale == "Log10") {
    scales = {
      ms: {
        distr: 3,
      },
      reqs: {
        distr: 3
      }
    }
  }

	let existing = document.getElementById("chart1");
	existing && existing.remove();

	let opts = {
		title: "Web Request Response Time [ms]",
		id: "chart1",
		class: "my-chart",
		width: rect.width,
		height: rect.height,
		labelSize: 100,
		scales: scales,
		labelFont: "bold 8px Arial",
		font: "8px Arial",
		axes: [
			{ grid: { show: false }},
			{
				scale: "ms",
				// grid: { show: false },
        values: (u, vals, space) => vals.map((val) => format_time(val)),
        size: 80,
			},
			{
				scale: "reqs",
				side: 1,
        values: (u, vals, space) => vals.map((val) => format_requests(val)),
				grid: { show: false },
        size: 100,
			},
		],
		series: [
			{ value: '{YYYY}-{MM}-{DD} {HH}:{mm}:{ss}' },
			{
				label: "P99",
				stroke: "rgb(155, 214, 206)",
				value: (self, rawValue) => format_time(rawValue),
				fill: "rgb(155, 214, 206, 0.5 )",
				paths: paths,
        scale: "ms",
        points: { show: false },
        ticks: { show: false }
			},
			{
				label: "P90",
				stroke: "rgb(79, 169, 184)",
				value: (self, rawValue) => format_time(rawValue),
				fill: "rgb(79, 169, 184, 0.5)",
				paths: paths,
				scale: "ms",
        points: { show: false },
        ticks: { show: false }
			},
			{
				label: "P50",
				stroke: "rgb(2, 88, 115)",
				value: (self, rawValue) => format_time(rawValue),
				fill: "rgb(2, 88, 115, 0.5)",
				paths: paths,
        points: { show: false },
        ticks: { show: false },
				scale: "ms"
			},
			{
				label: "Throughput",
				stroke: "rgb(30, 30, 30)",
				value: (self, rawValue) => format_requests(rawValue),
        points: { show: false },
        ticks: { show: false },
				scale: "reqs"
			}
		]
	};

	chart = new uPlot(opts, data, document.getElementById("chart"));
}

let scale = "";

export const ChartData = {
	mounted() {
		scale = JSON.parse(this.el.dataset.scale);
		let quantile_data = JSON.parse(this.el.dataset.quantile);
		create_chart(quantile_data, scale);
	},
	updated() {
		let new_scale = JSON.parse(this.el.dataset.scale);
		if (scale == new_scale) {
			let quantile_data = JSON.parse(this.el.dataset.quantile);
			chart.setData(quantile_data, scale);
		} else {
			this.mounted();
		}
	}
}
