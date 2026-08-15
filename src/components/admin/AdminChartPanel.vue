<script setup lang="ts">
import { TrendingUp } from "@lucide/vue"
import { ChartContainer } from "@/components/ui/chart"

import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"

import { VisArea, VisAxis, VisXYContainer } from "@unovis/vue"

const props = defineProps({
  data: { type: Array, required: false, default: () => [] },
  config: { type: Object, required: false, default: () => ({}) },
  xKey: { type: String, required: false, default: "month" },
  yKey: { type: String, required: false, default: "desktop" },
})

const xAccessor = (d: any) => d[props.xKey]
const yAccessor = (d: any) => d[props.yKey]

const svgDefs = `
  <linearGradient id="fillDesktop" x1="0" y1="0" x2="0" y2="1">
    <stop offset="5%" stop-color="var(--primary)" stop-opacity="0.8" />
    <stop offset="95%" stop-color="var(--primary)" stop-opacity="0.1" />
  </linearGradient>

  <linearGradient id="fillMobile" x1="0" y1="0" x2="0" y2="1">
    <stop offset="5%" stop-color="var(--secondary)" stop-opacity="0.8" />
    <stop offset="95%" stop-color="var(--secondary)" stop-opacity="0.1" />
  </linearGradient>
`
</script>

<template>
  <Card class="rounded-2xl">

    <CardHeader>
      <CardTitle>
        Area Chart - Gradient
      </CardTitle>

      <CardDescription>
        Showing total visitors for the last 6 months
      </CardDescription>
    </CardHeader>

    <CardContent>
      <ChartContainer :config="props.config">

        <VisXYContainer :data="props.data" :svg-defs="svgDefs" class="h-[300px] w-full">

          <VisArea :x="xAccessor" :y="yAccessor" color="url(#fillDesktop)" :opacity="1" />

          <VisAxis type="x" :tick-line="false" :domain-line="false" :grid-line="false" :num-ticks="6" />

          <VisAxis type="y" :num-ticks="3" :tick-line="false" :domain-line="false" />

        </VisXYContainer>

      </ChartContainer>
    </CardContent>

    <CardFooter>
      <div class="flex w-full items-start gap-2 text-sm">

        <div class="grid gap-2">

          <div class="flex items-center gap-2 leading-none font-medium">
            Trending up by 5.2% this month
            <TrendingUp class="h-4 w-4" />
          </div>

          <div class="text-muted-foreground flex items-center gap-2 leading-none">
            January - June 2026
          </div>

        </div>

      </div>
    </CardFooter>

  </Card>
</template>