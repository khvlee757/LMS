<script setup>
import { DotLottieVue } from "@lottiefiles/dotlottie-vue";
import northstarMark from "@/assets/northstar-mark.png";

defineProps({
  animationSrc: { type: String, required: true },
  sideLabel: { type: String, default: "NORTHSTAR LEARNING" },
  sideHeadline: { type: String, default: "Learning, with room to grow." },
  sideDescription: { type: String, default: "A thoughtful place to build skills, share knowledge, and keep moving forward." },
  formAtTop: { type: Boolean, default: false },
});
</script>

<template>
  <main class="grid h-screen grid-cols-1 overflow-hidden bg-white lg:grid-cols-[minmax(360px,0.86fr)_minmax(580px,1.14fr)]">
    <section class="relative hidden h-screen overflow-hidden bg-primary px-10 py-10 text-white lg:flex lg:flex-col xl:px-14" aria-hidden="true">
      <div class="relative z-10 flex items-center gap-3">
        <img :src="northstarMark" alt="" class="h-20" />
        <span class="text-md font-bold text-gold-300 uppercase">{{ sideLabel }}</span>
      </div>
      <div class="relative z-10 mt-20 max-w-lg">
        <p class="mb-4 text-xs font-bold uppercase text-accent">A NEW CHAPTER</p>
        <h1 class="max-w-md text-4xl font-extrabold leading-tight xl:text-5xl">{{ sideHeadline }}</h1>
        <p class="mt-5 max-w-sm text-base leading-7 text-white/75">{{ sideDescription }}</p>
      </div>
      <div class="pointer-events-none absolute bottom-14 left-1/2 h-[43%] w-[82%] -translate-x-1/2 opacity-90">
        <DotLottieVue :src="animationSrc" autoplay loop class="h-full w-full" />
      </div>
      <div class="relative z-10 mt-auto flex items-center gap-3 border-t border-white/20 pt-5 text-xs text-white/70">
        <span class="size-2 rounded-full bg-accent" />
        Learn at your own pace. Teach what you know.
      </div>
    </section>
    <section class="flex h-screen min-h-0 justify-center overflow-y-auto px-5 py-8 sm:px-8 lg:px-10 xl:px-14" :class="formAtTop ? 'items-start' : 'items-center'">
      <div class="my-auto w-full max-w-2xl py-2 reveal-on-enter" style="--reveal-delay: 80ms">
        <slot />
      </div>
    </section>
  </main>
</template>
