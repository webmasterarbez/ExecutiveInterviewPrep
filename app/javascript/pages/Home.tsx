import { Button } from '@/components/ui/button'
import { Heart, Star, Zap, Rocket, Sparkles } from 'lucide-react'

export default function Home() {
  return (
    <div className="container mx-auto p-8">
      <h1 className="text-4xl font-bold mb-4">Hello World</h1>
      <p className="text-lg mb-6">
        This is an example root page with example components:
      </p>

      <div className="mb-8">
        <h2 className="text-2xl font-semibold mb-4">Lucide Icons</h2>
        <div className="flex flex-wrap gap-6 items-center">
          <div className="flex flex-col items-center gap-2">
            <Heart className="w-12 h-12 text-red-500" />
            <span className="text-sm">Heart</span>
          </div>
          <div className="flex flex-col items-center gap-2">
            <Star className="w-12 h-12 text-yellow-500" />
            <span className="text-sm">Star</span>
          </div>
          <div className="flex flex-col items-center gap-2">
            <Zap className="w-12 h-12 text-blue-500" />
            <span className="text-sm">Zap</span>
          </div>
          <div className="flex flex-col items-center gap-2">
            <Rocket className="w-12 h-12 text-purple-500" />
            <span className="text-sm">Rocket</span>
          </div>
          <div className="flex flex-col items-center gap-2">
            <Sparkles className="w-12 h-12 text-pink-500" />
            <span className="text-sm">Sparkles</span>
          </div>
        </div>
      </div>

      <div className="flex flex-wrap gap-4">
        <Button>Example Button</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="destructive">Destructive</Button>
        <Button variant="outline">Outline</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="link">Link</Button>
      </div>
    </div>
  )
}
