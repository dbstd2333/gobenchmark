/*
 * Copyright 2022 CloudWeGo Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package runner

import (
	"sync"
	"time"

	"github.com/cloudwego/hertz/pkg/common/hlog"
)

// 为了流量更均匀, 时间间隔设置为 10ms
const window = 10 * time.Millisecond

// 单次测试
type RunOnce func() error

type Runner struct {
	counter *Counter // 计数器
	timer   *Timer   // 计时器
}

func NewRunner() *Runner {
	r := &Runner{
		counter: NewCounter(),
		timer:   NewTimer(time.Microsecond),
	}
	return r
}

func (r *Runner) benching(onceFn RunOnce, concurrent int, total int64) {
	var wg sync.WaitGroup
	wg.Add(concurrent)
	r.counter.Reset(total)
	for i := 0; i < concurrent; i++ {
		go func() {
			defer wg.Done()
			for {
				idx := r.counter.Idx()
				if idx >= total {
					return
				}
				begin := r.timer.Now()
				err := onceFn()
				end := r.timer.Now()
				cost := end - begin
				r.counter.AddRecord(idx, err, cost)
			}
		}()
	}
	wg.Wait()
	r.counter.Total = total
}

func (r *Runner) Warmup(onceFn RunOnce, concurrent int, total int64) {
	r.benching(onceFn, concurrent, total)
}

// 并发测试
func (r *Runner) Run(title string, onceFn RunOnce, size, concurrent int, total int64, bodySize, headerSize int) {
	logInfo(
		"%s start benching, body size: %d, header size: %d. concurrent: %d, total: %d",
		blueString("["+title+"]"), size, headerSize, concurrent, total,
	)

	start := r.timer.Now()
	r.benching(onceFn, concurrent, total)
	stop := r.timer.Now()
	err := r.counter.Report(title, stop-start, concurrent, total, bodySize, headerSize)
	if err != nil {
		hlog.Error(err)
	}
}
