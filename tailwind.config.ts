import type { Config } from "tailwindcss";
export default { content: ["./app/**/*.{ts,tsx}","./components/**/*.{ts,tsx}"], theme: { extend: { colors: { ink:"#08090d", panel:"#101219", lime:"#a5ff35", muted:"#9699a6" }, fontFamily: { display:["Barlow Condensed","sans-serif"], sans:["DM Sans","sans-serif"] }, boxShadow: { glow:"0 0 32px #a5ff3525" } } }, plugins: [] } satisfies Config;
